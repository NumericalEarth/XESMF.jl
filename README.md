# XESMF.jl

Julia wrapper for [xESMF](https://github.com/pangeo-data/xESMF), a python package maintained by [pangeo](https://pangeo.io/).

<a href="https://numericalearth.github.io/XESMF.jl/stable">
  <img alt="Stable documentation" src="https://img.shields.io/badge/documentation-stable%20release-blue">
</a>

<a href="https://numericalearth.github.io/XESMF.jl/dev">
  <img alt="Development documentation" src="https://img.shields.io/badge/documentation-in%20development-orange">
</a>

<a href="https://github.com/NumericalEarth/XESMF.jl/actions">
  <img alt="CI" src="https://github.com/NumericalEarth/XESMF.jl/actions/workflows/CI.yml/badge.svg">
</a>

<a href="https://codecov.io/gh/NumericalEarth/XESMF.jl" >
  <img src="https://codecov.io/gh/NumericalEarth/XESMF.jl/graph/badge.svg?token=ABAQ8KC347"/>
</a>

## Overview

XESMF.jl provides a Julia interface to the [xESMF](https://github.com/pangeo-data/xESMF) (xarray Earth System Model Exchange Format) Python library, which provides tools for interpolating and regridding fields between arbitrary grids.
This wrapper provides regridding functionality for [Oceananigans.jl](https://github.com/CliMA/Oceananigans.jl).

## Installation

```julia
using Pkg
Pkg.add("XESMF")
```

## Documentation

Documentation is available at https://numericalearth.github.io/XESMF.jl/stable

## Contributing

Only a subset of the [xESMF](https://github.com/pangeo-data/xESMF) python package functionality is exposed.
Open an [issue](https://github.com/NumericalEarth/XESMF.jl/issues/new) or a [pull request](https://github.com/NumericalEarth/XESMF.jl/pulls) if you'd like to extend more of Python's xESMF functionality via this wrapper.

## License

This package uses the MIT license.
