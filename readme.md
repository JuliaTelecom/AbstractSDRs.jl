<div align="center">
<img src="docs/src/assets/logoAbstractSDRs.png" alt="UHDBindings.jl" width="380">
</div>

# AbstractSDRs.jl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rgerzaguet.github.io/AbstractSDRs.jl/dev/index.html)


## Purpose 

This package proposes a single API to monitor different kind of Software Defined Radio. With AbstractSDRs, the following SDRs can be used 
- All Universal Software Radio Peripheral [USRP](https://files.ettus.com/manual/), based on [UHDBindings](https://github.com/RGerzaguet/UHDBindings.jl) package
- TRL SDR dongle, with inclusion of [RTLSDR package](https://github.com/dressel/RTLSDR.jl)
- Any UHD device connectted to a remote PC with a network connection (for instance, Exxx USRP device) on which a Julia session works.

AbstractSDRs provides an unified API to open, transmit and received samples and close the SDRs. 

For instance, in order to get 4096 samples at 868MHz with a instantaneous bandwidth of 16MHz, with a 30dB Rx Gain, assuming that a USRP is connected, the following Julia code will do the trick and returns a vector with type Complex{Cfloat} with 4096 samples.

	function main()
		# ---------------------------------------------------- 
		# --- Physical layer and RF parameters 
		# ---------------------------------------------------- 

		carrierFreq		= 868e6;	# --- The carrier frequency 	
		samplingRate		= 16e6;         # --- Targeted bandwdith 
		rxGain			= 30.0;         # --- Rx gain 
		nbSamples		= 4096;         # --- Desired number of samples
	
		# ---------------------------------------------------- 
		# --- Getting all system with function calls  
		# ---------------------------------------------------- 
		# --- Creating the radio ressource 
		# The first parameter is to tune the Rx board
		radio	= openSDR("UHDRx",carrierFreq,samplingRate,rxGain);
		# --- Display the current radio configuration
		print(radio);
		# --- Getting a buffer from the radio 
		sig	= recv(radio,nbSamples);
		# --- Release the radio ressources
		close(radio); 
		# --- Output to signal 
		return sig;
	end

Note that the SDR discrimination is done through the "UHDRx" parameter when opening the device, which states here that the UHD driver should be used, and that the radio will receive samples.
To get the same functionnality with a RTL SDR dongle, the following code can be used.

	function main()
		# ---------------------------------------------------- 
		# --- Physical layer and RF parameters 
		# ---------------------------------------------------- 

		carrierFreq		= 868e6;	# --- The carrier frequency 	
		samplingRate		= 16e6;         # --- Targeted bandwdith 
		rxGain			= 30.0;         # --- Rx gain 
		nbSamples		= 4096;         # --- Desired number of samples
	
		# ---------------------------------------------------- 
		# --- Getting all system with function calls  
		# ---------------------------------------------------- 
		# --- Creating the radio ressource 
		# The first parameter is to tune the Rx board
		radio	= openSDR("RTLRx",carrierFreq,samplingRate,rxGain);
		# --- Display the current radio configuration
		print(radio);
		# --- Getting a buffer from the radio 
		sig	= recv(radio,nbSamples);
		# --- Release the radio ressources
		close(radio); 
		# --- Output to signal 
		return sig;
	end

Note that the only difference lies in the radio opening.

## Installation

The package can be installed with the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```
pkg> add AbstractSDRs 
```

Or, equivalently, via the `Pkg` API:

```julia
julia> import Pkg; Pkg.add("AbstractSDRs")
```

## Documentation

- [**STABLE**](https://rgerzaguet.github.io/UHDBindings.jl/dev/index.html) &mdash; **documentation of the most recently tagged version.**
