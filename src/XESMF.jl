module XESMF

using CondaPkg
using PythonCall
using SparseArrays

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

end # module XESMF
