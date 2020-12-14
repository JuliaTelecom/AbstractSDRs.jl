<div align="center">
<img src="docs/src/assets/logoAbstractSDRs.png" alt="UHDBindings.jl" width="420">
</div>

# AbstractSDRs.jl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rgerzaguet.github.io/AbstractSDRs.jl/dev/index.html)


## Purpose 

This package proposes a single API to monitor different kind of Software Defined Radio.  We define several SDR backends that can be piloted by the same API. With AbstractSDRs, the following SDRs can be used 
- All Universal Software Radio Peripheral [USRP](https://files.ettus.com/manual/), based on [UHDBindings](https://github.com/RGerzaguet/UHDBindings.jl) package
- RTL SDR dongle, with inclusion of [RTLSDR package](https://github.com/dressel/RTLSDR.jl)
- Any device connected to a remote PC with a network connection (for instance, Exxx USRP device) on which a Julia session works and run AbstractSDRs package.
- The ADALM Pluto SDR, through a specific package (WIP) 
- A pure simulation package usefull for testing without radio or do re-doing offline dataflow processing based on a given buffer 

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

## Backends 

AbstractSDRs wraps and implements different SDR backends that can be used when opening a radio device. The current list of supported SDR backends can be obtained via `getSupportedSDR`. 
When instantiate a radio device (with `openSDR`), the first argument is the radio backend and parameters associated to a specific backend can be used with keywords. 
Some specific functions can also be exported based in the selected backend. The list is given in the sub-backend part  

### UHD backend 

AbstractSDRs can be used with Universal Radio Peripheral (USRP) with the use of `UHDBindings.jl` package. The backend is identified by the symbol `:uhd`. This backend supports ths following keywords 
- `args=""` to specify any UHD argument in initialisation. Please refer to the UHD doc. For instance, FPGA bitstream path can be specified with `args="fgpa=path/to/image.bit"`. The IP address of the USRP can be added with `args="addr=192.168.10.xx"`.   

AbstractSDRs package also exports the following specific functions
- NONE. 

### RadioSim

This backend is useful when one wants to test a processing chain without having a radio as it simulates the behaviour of a SDR (configuration and buffer management). It is also useful when you have some acquisition in a given file (or buffer) as we can give the radio device a buffer which is then used to provide samples (as `recv` gives chunk of this buffer based on the desired size in a circular manner).     
This backend supports ths following keywords
- `packetSize` to specify the size of each packet given by the radio. By default the value is 1024 complex samples 
- `buffer` to give to the radio a buffer to be used when emulating the reception. The following rules occur 
  - If `packetSize` is not given, the provided buffer will be `buffer` each time the `recv` command is used
  - If `packetSize` is higher than the size of the proposed buffer, the buffer will be circulary copied to provive `packetSize` complex samples 
  - If `packetSize` is lower than the size of the proposed buffer, `recv` will returns `packetSize` samples from `buffer` and the buffer will be browsed cicularly 
  - If no buffer is given, `packetSize` random data will be generated at the init of the radio and proposed each time `recv`is called
AbstractSDRs package also exports the following specific functions related to RadioSims
- `updatePacketSize` to update the size of the radio packet. 
- `updateBuffer` to update the radio buffer 

### Pluto 

This backend can be used with ADALM Pluto SDR device. 

## SDROverNetworks

## Documentation

- [**STABLE**](https://juliatelecom.github.io/AbstractSDRs.jl/dev/index.html) &mdash; **documentation of the most recently tagged version.**
