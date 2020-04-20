# UHDBindings.jl


## Purpose 

This simple package proposes some bindings to the UHD, the C driver of the Universal Software Radio Peripheral [USRP](https://files.ettus.com/manual/) 

The purpose is to able to see the radio peripheral inside a Julia session and to be able to send and receive complex samples direclty within a Julia session. 


## Installation

The package can be installed with the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```
pkg> add UHDBindings
```

Or, equivalently, via the `Pkg` API:

```julia
julia> import Pkg; Pkg.add("UHDBindings")
```


## Documentation 


- The base documentation with the different functions can be found [in the base section](base.md)
- Different examples are described in [in the example section](examples.md). Other examples are provided in the example subfolder of the project. 
