module DiBitVector

import Base: getindex, setindex!, size, length

const SHIFT=5  # 32

struct DiBitVec <: AbstractVector{UInt8}
    n::Integer
    data::Array{UInt64}
    function DiBitVec(n::Integer, v::Integer = 0)
        ndiv, nrem = divrem(n, 32)
        if nrem > 0
            nrem = 1
        end
        ndiv += nrem
        # println("ndiv = $ndiv")
        if v == 0
            data = zeros(UInt64, ndiv)
        elseif v == 3
            data = fill(typemax(UInt64), ndiv)
        else
            val = UInt64(v)
            for i = 2:32
                val = val << 2 + v
            end
            data = fill(val, ndiv)
        end
        return new(n, data)
    end
end

@inline checkbounds(D::DiBitVec, n::Integer) = 1 ≤ n ≤ D.n || throw(BoundsError(D, n))
@inline function getoffset(n::Integer)
    ndiv = n >> SHIFT
    nrem = n & 0b11111
    ndiv += ifelse(nrem > 0, 1, 0)
    # println("n = $n, ndiv = $ndiv, nrem = $nrem")
    (ndiv, nrem*2)
end

"""
    _set_dibit!(D, n, v)

Sets index v of DiBitVec D to value n.
"""
@inline function unsafe_set_dibit!(D::DiBitVec, n::Integer, v::Integer)
    ndiv, nrem = getoffset(n)
    # println("ndiv = $ndiv, nrem = $nrem")
    mask = UInt64(0b11) << nrem
    val = @inbounds D.data[ndiv] & ~mask
    # println("val = $val, mask = $mask")
    val += (v << nrem)
    # println("ndiv = $ndiv, nrem = $nrem, v = $v, val = $val, mask = $mask")
    # println("typeof(val) = $(typeof(val))")
    @inbounds D.data[ndiv] = val
end

@inline function setindex!(D::DiBitVec, v::Integer, n::Integer) 
    (0 ≤ v ≤ 3) || throw(DomainError(v, "Values must be between 0 and 3."))
    @boundscheck checkbounds(D, n)
    unsafe_set_dibit!(D, n, v)
end

@inline function unsafe_get_dibit(D::DiBitVec, n::Integer)
    ndiv, nrem = getoffset(n)
    # println("ndiv = $ndiv, nrem = $nrem")
    b1 = @inbounds D.data[ndiv] >> (nrem) & 0b11
    return UInt8(b1)
end

@inline function getindex(D::DiBitVec, n::Integer)
    @boundscheck checkbounds(D, n) 
    unsafe_get_dibit(D, n)
end

@inline length(D::DiBitVec) = D.n
@inline size(D::DiBitVec) = (D.n, )

export DiBitVec

end # module
