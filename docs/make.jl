push!(LOAD_PATH, "../src/")
using Documenter , UHDBindings

makedocs(sitename="AbstractSDRs.jl", 
		 format = Documenter.HTML(),
		 pages    = Any[
						"Introduction to UHDBindings"   => "index.md",
						"Function list"         => "base.md",
						"Examples"              => Any[ 
														 "Examples/example_setup.md"
														 "Examples/example_parameters.md"
														 "Examples/example_benchmark.md"
														 ],
						],
		 );

#makedocs(sitename="My Documentation", format = Documenter.HTML(prettyurls = false))

deploydocs(
    repo = "github.com/RGerzaguet/AbstractSDRs.jl",
)
