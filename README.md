# XESMF.jl

Julia wrapper for [xESMF](https://github.com/pangeo-data/xESMF), a python package maintained by [pangeo](https://pangeo.io/).

[![CI](https://github.com/NumericalEarth/XESMF.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/NumericalEarth/XESMF.jl/actions)
[![Documentation](https://github.com/numericalearth/XESMF.jl/actions/workflows/documentation.yml/badge.svg)](https://NumericalEarth.github.io/XESMF.jl/)

## Overview

XESMF.jl provides a Julia interface to the [xESMF](https://github.com/pangeo-data/xESMF) (xarray Earth System Model Exchange Format) Python library, which provides tools for interpolating and regridding fields between arbitrary grids.
This wrapper provides regridding functionality for [Oceananigans.jl](https://github.com/CliMA/Oceananigans.jl).

## Installation

```julia
using Pkg
Pkg.add("XESMF")
```

## Documentation

Documentation is available at https://numericalearth.github.io/XESMF.jl/

## Contributing

At the moment only a subset of the [xESMF](https://github.com/pangeo-data/xESMF) python package functionality is exposed.
Open an [issue](https://github.com/NumericalEarth/XESMF.jl/issues/new) or a [pull request](https://github.com/NumericalEarth/XESMF.jl/pulls) if you'd like to extend more of Python's xESMF functionality via this wrapper.

## License

This package uses the MIT license.
