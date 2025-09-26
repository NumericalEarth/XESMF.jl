module XESMF

using CondaPkg
using PythonCall
using SparseArrays

struct Regridder{S, M, V1, V2}
    method :: M
    weights :: S
    src_temp :: V1
    dst_temp :: V2
end

Base.summary(r::Regridder{S, M, V1, V2}) where {S, M, V1, V2} = "$(r.method) Regridder"

function Base.show(io::IO, r::Regridder)
    print(io, summary(r), '\n')
    print(io, "├── weights: ", summary(r.weights), '\n')
    print(io, "├── src_temp: ", summary(r.src_temp), '\n')
    print(io, "└── dst_temp: ", summary(r.dst_temp))
end

function extract_xesmf_coordinates_structure end

"""
    sparse_regridder_weights(FT, regridder)

Return the regridder weights as a sparse matrix.
"""
function sparse_regridder_weights(FT, regridder)
    coords = regridder.weights.data
    shape  = pyconvert(Tuple{Int, Int}, coords.shape)
    vals   = pyconvert(Array{FT}, coords.data)
    coords = pyconvert(Array{FT}, coords.coords)
    rows = coords[1, :] .+ 1
    cols = coords[2, :] .+ 1

    weights = sparse(rows, cols, vals, shape[1], shape[2])

    return weights
end

sparse_regridder_weights(regridder) = sparse_regridder_weights(Float64, regridder)

"""
    Regridder(src_coordinates::Dict{String, <:AbstractArray},
              dst_coordinates::Dict{String, <:AbstractArray};
              method="conservative", periodic=false)

Return a Regridder from the xESMF Python package to regrid data from
`src_coordinates` to `dst_coordinates` using the specified `method`.

The `src_coordinates` and `dst_coordinates` are dictionaries that contain
information about the two grids.

xESMF exposes five different regridding algorithms from the ESMF library,
specified with the `method` keyword argument:

* `"bilinear"`: `ESMF.RegridMethod.BILINEAR`
* `"conservative"`: `ESMF.RegridMethod.CONSERVE`
* `"conservative_normed"`: `ESMF.RegridMethod.CONSERVE`
* `"patch"`: `ESMF.RegridMethod.PATCH`
* `"nearest_s2d"`: `ESMF.RegridMethod.NEAREST_STOD`
* `"nearest_d2s"`: `ESMF.RegridMethod.NEAREST_DTOS`

where `conservative_normed` is just the conservative method with the normalization set to
`ESMF.NormType.FRACAREA` instead of the default `norm_type = ESMF.NormType.DSTAREA`.

For more information, see the Python xESMF documentation at:

> https://xesmf.readthedocs.io/en/latest/notebooks/Compare_algorithms.html
"""
function Regridder(src_coordinates::Dict{String, <:AbstractArray},
                   dst_coordinates::Dict{String, <:AbstractArray};
                   method="conservative", periodic=false)

    xesmf = XESMF.xesmf
    regridder = xesmf.Regridder(src_coordinates, dst_coordinates, method; periodic)
    method = uppercasefirst(string(regridder.method))

    weights = XESMF.sparse_regridder_weights(regridder)

    Ndst, Nsrc = size(weights)

    temp_src = zeros(Nsrc)
    temp_dst = zeros(Ndst)

    return Regridder(method, weights, temp_src, temp_dst)
end

# Placeholder (will be overwritten in __init__)
xesmf = Py(nothing)

function __init__()
    global xesmf
    try
        xesmf = pyimport("xesmf")
    catch e
        if occursin("No module named 'ESMF'", string(e))
            error("""
            XESMF.jl requires the ESMF library to be installed.
            This is usually handled automatically by CondaPkg, but on some systems
            (particularly Windows) it may need to be installed manually.

            Try running:
            julia -e "using CondaPkg; CondaPkg.add(["esmf", "esmpy"])"
            """)
        else
            rethrow(e)
        end
    end
end

end # module XESMF
