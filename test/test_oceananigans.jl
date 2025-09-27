include("setup_runtests.jl")

using Oceananigans
using Oceananigans.Fields: AbstractField
using SparseArrays

function x_node_array(x::AbstractVector, Nx, Ny)
    return Array(repeat(view(x, 1:Nx), 1, Ny))'
end
function  y_node_array(x::AbstractVector, Nx, Ny)
    return Array(repeat(view(x, 1:Ny)', Nx, 1))'
end
x_node_array(x::AbstractMatrix, Nx, Ny) = Array(view(x, 1:Nx, 1:Ny))'

function x_vertex_array(x::AbstractVector, Nx, Ny)
    return Array(repeat(view(x, 1:Nx+1), 1, Ny+1))'
end
function y_vertex_array(x::AbstractVector, Nx, Ny)
    return Array(repeat(view(x, 1:Ny+1)', Nx+1, 1))'
end
x_vertex_array(x::AbstractMatrix, Nx, Ny) = Array(view(x, 1:Nx+1, 1:Ny+1))'

y_node_array(x::AbstractMatrix, Nx, Ny) = x_node_array(x, Nx, Ny)
y_vertex_array(x::AbstractMatrix, Nx, Ny) = x_vertex_array(x, Nx, Ny)

function extract_xesmf_coordinates_structure(dst_field::AbstractField, src_field::AbstractField)
    ℓx, ℓy, ℓz = Oceananigans.Fields.instantiated_location(src_field)

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

    # Build data structures expected by xESMF
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

    return dst_coordinates, src_coordinates
end

@testset "Oceananigans Integration Tests" begin
    @testset "Grid Regridding Tests" begin
        # Create smaller test grids to avoid memory issues
        tg = TripolarGrid(size=(360, 170, 1), z=(0, 1))
        ll = LatitudeLongitudeGrid(size=(360, 180, 1), longitude=(0, 360), latitude=(-90, 90), z=(0, 1))

        ctg = CenterField(tg)
        cll = CenterField(ll)

        # Test that we can create the coordinate structures
        dst_coordinates, src_coordinates = extract_xesmf_coordinates_structure(cll, ctg)

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

        periodic = Oceananigans.Grids.topology(ctg.grid, 1) === Periodic ? true : false
        method = "conservative"
        regridder = XESMF.Regridder(src_coordinates, dst_coordinates; method, periodic)

        @test regridder.weights isa SparseMatrixCSC

        # test that the regridder works with dense and strided arrays
        dense_tg = zeros(prod(size(tg)))
        dense_ll = zeros(prod(size(ll)))

        strided_tg = vec(view(zeros(size(tg, 1)+5, size(tg, 2)+5), 1:size(tg, 1), 1:size(tg, 2)))
        strided_ll = vec(view(zeros(size(ll, 1)+5, size(ll, 2)+5), 1:size(ll, 1), 1:size(ll, 2)))

        rand_tg = rand(prod(size(tg)))
        rand_ll = rand(prod(size(ll)))

        dense_tg .= rand_tg
        strided_tg .= rand_tg
        regridder(dense_ll, dense_tg)
        regridder(strided_ll, strided_tg)

        @test all(dense_ll .== strided_ll)
    end
end
