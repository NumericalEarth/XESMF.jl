include("setup_runtests.jl")
using SparseArrays

x_node_array(x::AbstractVector, Nx, Ny) = view(x, 1:Nx) |> Array
y_node_array(x::AbstractVector, Nx, Ny) = view(x, 1:Ny) |> Array
x_node_array(x::AbstractMatrix, Nx, Ny) = view(x, 1:Nx, 1:Ny) |> Array

x_vertex_array(x::AbstractVector, Nx, Ny) = view(x, 1:Nx+1) |> Array
y_vertex_array(x::AbstractVector, Nx, Ny) = view(x, 1:Ny+1) |> Array
x_vertex_array(x::AbstractMatrix, Nx, Ny) = view(x, 1:Nx+1, 1:Ny+1) |> Array

y_node_array(x::AbstractMatrix, Nx, Ny) = x_node_array(x, Nx, Ny)
y_vertex_array(x::AbstractMatrix, Nx, Ny) = x_vertex_array(x, Nx, Ny)

function regridding_weights(dst_field, src_field)
    ℓx, ℓy, ℓz = Oceananigans.Fields.instantiated_location(src_field)

    # We only support regridding between centered fields.
    @assert ℓx isa Center
    @assert ℓy isa Center
    @assert (ℓx, ℓy, ℓz) == Oceananigans.Fields.instantiated_location(dst_field)

    dst_grid = dst_field.grid
    src_grid = src_field.grid

    # Extract center coordinates from both fields
    λᵈ = λnodes(dst_grid, Center(), Center(), ℓz, with_halos=true)
    φᵈ = φnodes(dst_grid, Center(), Center(), ℓz, with_halos=true)
    λˢ = λnodes(src_grid, Center(), Center(), ℓz, with_halos=true)
    φˢ = φnodes(src_grid, Center(), Center(), ℓz, with_halos=true)

    # Extract cell vertices
    λvᵈ = λnodes(dst_grid, Face(), Face(), ℓz, with_halos=true)
    φvᵈ = φnodes(dst_grid, Face(), Face(), ℓz, with_halos=true)
    λvˢ = λnodes(src_grid, Face(), Face(), ℓz, with_halos=true)
    φvˢ = φnodes(src_grid, Face(), Face(), ℓz, with_halos=true)

    # Build data structures expected by XESMF.
    Nˢx, Nˢy, Nˢz = size(src_field)
    Nᵈx, Nᵈy, Nᵈz = size(dst_field)

    λᵈ = x_node_array(λᵈ, Nᵈx, Nᵈy)
    φᵈ = y_node_array(φᵈ, Nᵈx, Nᵈy)
    λˢ = x_node_array(λˢ, Nˢx, Nˢy)
    φˢ = y_node_array(φˢ, Nˢx, Nˢy)

    λvᵈ = x_vertex_array(λvᵈ, Nᵈx, Nᵈy)
    φvᵈ = y_vertex_array(φvᵈ, Nᵈx, Nᵈy)
    λvˢ = x_vertex_array(λvˢ, Nˢx, Nˢy)
    φvˢ = y_vertex_array(φvˢ, Nˢx, Nˢy)

    dst_coordinates = Dict("lat"   => φᵈ,  # φ is latitude
                           "lon"   => λᵈ,  # λ is longitude
                           "lat_b" => φvᵈ,
                           "lon_b" => λvᵈ)

    src_coordinates = Dict("lat"   => φˢ,  # φ is latitude
                           "lon"   => λˢ,  # λ is longitude
                           "lat_b" => φvˢ,
                           "lon_b" => λvˢ)

    return src_coordinates, dst_coordinates
end

@testset "Oceananigans Integration Tests" begin
    @testset "Grid Regridding Tests" begin
        # Create smaller test grids to avoid memory issues
        tg = TripolarGrid(size=(360, 170, 1), z=(0, 1))
        ll = LatitudeLongitudeGrid(size=(360, 180, 1), longitude=(0, 360), latitude=(-90, 90), z=(0, 1))

        ctg = CenterField(tg)
        cll = CenterField(ll)

        # Test that we can create the coordinate structures
        src_coordinates, dst_coordinates = regridding_weights(ctg, cll)

        # Verify coordinate structures are valid
        @test haskey(src_coordinates, "lat")
        @test haskey(src_coordinates, "lon")
        @test haskey(src_coordinates, "lat_b")
        @test haskey(src_coordinates, "lon_b")

        @test haskey(dst_coordinates, "lat")
        @test haskey(dst_coordinates, "lon")
        @test haskey(dst_coordinates, "lat_b")
        @test haskey(dst_coordinates, "lon_b")

        # Test basic grid properties
        @test size(tg) == (360, 170, 1)
        @test size(ll) == (360, 180, 1)

        @show xesmf = XESMF.xesmf # not working, returns Python: NULL
        @show xesmf = XESMF.pyimport("xesmf")
        periodic = Oceananigans.Grids.topology(ctg.grid, 1) === Periodic ? PythonCall.pybuiltins.True : pybuiltins.False
        method = "conservative"
        regridder = xesmf.Regridder(src_coordinates, dst_coordinates, method; periodic)
        weights = XESMF.sparse_regridder_weights(regridder)
    end
end
