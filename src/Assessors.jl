# ----------------------------------------------------
# --- Accessor.jl
# ---------------------------------------------------- 
# Function to access to radio parameters

getError(obj::UHDBinding) = UHDBindings.getError(obj);
getError(obj::RadioSim) = RadioSims.getError(obj);
getError(obj::SDROverNetwork) = SDROverNetworks.getMD(obj)[3];
getError(obj::RTLSDRBinding) = RTLSDRBindings.getError(obj);
getError(obj::BladeRFBinding) = BladeRFBindings.getError(obj);

getTimestamp(obj::UHDBinding) = UHDBindings.getTimestamp(obj);
getTimestamp(obj::RadioSim) = RadioSims.getTimestamp(obj);
getTimestamp(obj::SDROverNetwork) = SDROverNetworks.getMD(obj)[1:2];
getTimestamp(obj::RTLSDRBinding) = RTLSDRBindings.getTimestamp(obj);
getTimestamp(obj::BladeRFBinding) = BladeRFBindings.getTimestamp(obj);



""" 
Get the current sampling rate of the radio device 
The second parameter (optionnal) speicfies the Rx or Tx board (default : Rx)
""" 
getSamplingRate(obj::AbstractSDR;mode=:rx) = ((mode == :rx) ? Float64(obj.rx.samplingRate) : Float64(obj.tx.samplingRate))
getSamplingRate(obj::PlutoSDR;mode=:rx) = ((mode == :rx) ? Float64(obj.rx.effectiveSamplingRate) : Float64(obj.tx.effectiveSamplingRate))

""" 
Get the current carrier frequency   of the radio device 
The second parameter (optionnal) speicfies the Rx or Tx board (default : Rx)
""" 
getCarrierFreq(obj::AbstractSDR;mode=:rx) = (mode == :rx) ? Float64(obj.rx.carrierFreq) : Float64(obj.tx.carrierFreq)
getCarrierFreq(obj::PlutoSDR;mode=:rx) = (mode == :rx) ? Float64(obj.rx.effectiveCarrierFreq) : Float64(obj.tx.effectiveCarrierFreq)


""" 
Get the current radio gain 
The second parameter (optionnal) specifies the Rx or Tx board (default : Rx)
"""
getGain(obj::AbstractSDR;mode=:rx) = (mode == :rx) ? Float64(obj.rx.gain) : Float64(obj.tx.gain) 
getGain(obj::PlutoSDR;mode=:rx) = AdalmPluto.getGain(obj)


""" 
Check if a SDR has already been closed. The falg is true is the SDR ressources have been released and false otherwise.
# --- Syntax 
flag = isClosed(radio) 
# --- Input parameters 
- radio	  : SDR device
# --- Output parameters 
- flag : True is SDR is already closed, false otherwise
""" 
isClosed(obj::AbstractSDR)  = Bool(obj.tx.released) || Bool(obj.rx.released)
isClosed(obj::PlutoSDR)     = Bool(obj.released)


""" 
Returns the radio packet size. Each radio backend encapsulates the IQ samples into chunks of data. The `recv` command can be used with any size but it can be more efficient to match the desired size with the one provided by the radio 
# --- Syntax 
bufferSize = getBufferSize(radio) 
# --- Input parameters 
- radio	  : SDR device
# --- Output parameters 
bufferSize : Size of radio internal buffer 
""" 
getBufferSize(obj::AbstractSDR) = obj.rx.packetSize          # We get the fields 
getBufferSize(obj::PlutoSDR)    = obj.rx.buf.C_sample_size   # For Pluto this is hidden in the buffer config


