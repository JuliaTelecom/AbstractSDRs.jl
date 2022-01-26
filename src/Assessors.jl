# ----------------------------------------------------
# --- Accessor.jl
# ---------------------------------------------------- 
# Function to access to radio parameters

getError(obj::UHDBinding) = UHDBindings.getError(obj);
getError(obj::RadioSim) = RadioSims.getError(obj);
getError(obj::SDROverNetwork) = SDROverNetworks.getMD(obj)[3];
getError(obj::RTLSDRBinding) = RTLSDRBindings.getError(obj);

getTimestamp(obj::UHDBinding) = UHDBindings.getTimestamp(obj);
getTimestamp(obj::RadioSim) = RadioSims.getTimestamp(obj);
getTimestamp(obj::SDROverNetwork) = SDROverNetworks.getMD(obj)[1:2];
getTimestamp(obj::RTLSDRBinding) = RTLSDRBindings.getTimestamp(obj);

""" 
Get the current sampling rate of the radio device 
The second parameter (optionnal) speicfies the Rx or Tx board (default : Rx)
""" 
getSamplingRate(obj::AbstractSDR;mode=:rx) = ((mode == :rx) ? obj.rx.samplingRate : obj.tx.samplingRate)
getSamplingRate(obj::PlutoSDR;mode=:rx) = ((mode == :rx) ? obj.rx.effectiveSamplingRate : obj.tx.effectiveSamplingRate)

""" 
Get the current carrier frequency   of the radio device 
The second parameter (optionnal) speicfies the Rx or Tx board (default : Rx)
""" 
getCarrierFreq(obj::AbstractSDR;mode=:rx) = (mode == :rx) ? obj.rx.carrierFreq : obj.tx.carrierFreq
getCarrierFreq(obj::PlutoSDR;mode=:rx) = (mode == :rx) ? obj.rx.effectiveCarrierFreq : obj.tx.effectiveCarrierFreq


""" 
Get the current radio gain 
The second parameter (optionnal) specifies the Rx or Tx board (default : Rx)
"""
getGain(obj::AbstractSDR;mode=:rx) = (mode == :rx) ? obj.rx.gain : obj.tx.gain 
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

""" 
Returns the range of the carrier frequencies supported by the current radio devices. The output is a list or a range with the support carrier frequencies. By default it uses the first channel of the radio. For the SDRs that support, another channel can be used with te keyword `chan` 
    list_carrierFreq = getCarrierFreqRange(radio;chan=0)
"""
function getRxCarrierFreqRange(radio::UHDBinding;chan=0)
    # For some SDRs, we may have a function that direcly provides the range. However, it must be use with the appropriate container
    # Handle of radio 
    h = radio.rx.uhd.pointerUSRP
    # Handle of carrier frequency range 
    range_handle = Ref{UHDBindings.LibUHD.uhd_meta_range_handle}()
    UHDBindings.LibUHD.uhd_meta_range_make(range_handle)
    freq_range_out = range_handle[] # Init a pointer, use the dereferenced pointer
    # Call to the lib 
    UHDBindings.LibUHD.uhd_usrp_get_rx_freq_range(h, chan, freq_range_out)
    # Convert the handle as a list 
    # First we have a ion into strings 
    stringSize      = 1024
    stringContainer = String(ones(UInt8,stringSize)*UInt8(32))
    UHDBindings.LibUHD.uhd_meta_range_to_pp_string(freq_range_out,stringContainer,stringSize)
    # We have a range with start, stop, step 
    news = split(split(stringContainer,"\n")[1],",")
    startFreq = parse(Float64,news[1][2:end])  # Start with (
    stopFreq  = parse(Float64,news[2])
    stepFreq = parse(Float64,news[3][1:end-1]) # Stop with )
    # Create a range 
    freqRange = range(startFreq,step=stepFreq,stop=stopFreq)
    return freqRange
end
function getTxCarrierFreqRange(radio::UHDBinding;chan=0)
    # For some SDRs, we may have a function that direcly provides the range. However, it must be use with the appropriate container
    # Handle of radio 
    h = radio.tx.uhd.pointerUSRP
    # Handle of carrier frequency range 
    range_handle = Ref{UHDBindings.LibUHD.uhd_meta_range_handle}()
    UHDBindings.LibUHD.uhd_meta_range_make(range_handle)
    freq_range_out = range_handle[] # Init a pointer, use the dereferenced pointer
    # Call to the lib 
    UHDBindings.LibUHD.uhd_usrp_get_tx_freq_range(h, chan, freq_range_out)
    # Convert the handle as a list 
    # First we have a ion into strings 
    stringSize      = 1024
    stringContainer = String(ones(UInt8,stringSize)*UInt8(32))
    UHDBindings.LibUHD.uhd_meta_range_to_pp_string(freq_range_out,stringContainer,stringSize)
    # We have a range with start, stop, step 
    news = split(split(stringContainer,"\n")[1],",")
    startFreq = parse(Float64,news[1][2:end])  # Start with (
    stopFreq  = parse(Float64,news[2])
    stepFreq = parse(Float64,news[3][1:end-1]) # Stop with )
    # Create a range 
    freqRange = range(startFreq,step=stepFreq,stop=stopFreq)
    return freqRange
end
getRxCarrierFreqRange(radio::RadioSim;chan=0) = range(0,step=1,stop=16e9)
getTxCarrierFreqRange(radio::RadioSim;chan=0) = range(0,step=1,stop=16e9)
