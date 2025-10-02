using Documenter
using XESMF

# Set up the documentation
makedocs(
    sitename = "XESMF.jl",
    authors = "Gregory Wagner <wagner.greg@gmail.com>",
    modules = [XESMF],
    pages = [
        "Home" => "index.md",
        "API Reference" => "api.md",
        "Examples" => "examples.md",
        "Development" => "development.md",
    ],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://numericalearth.github.io/XESMF.jl",
        assets = String[],
    ),
    checkdocs = :exports,
    doctest = true,
)

# Deploy documentation to GitHub Pages
deploydocs(
    repo = "github.com/NumericalEarth/XESMF.jl.git",
    versions = ["stable" => "v^", "dev" => "dev", "v#.#.#"],
    forcepush = true,
    devbranch = "main",
    push_preview = true,
)
