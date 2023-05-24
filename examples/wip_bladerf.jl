using AbstractSDRs 

C = AbstractSDRs.BladeRFBindings.LibBladeRF 


carrierFreq = 868e6 
samplingRate = 50e6 
gain = 12 


sdr = AbstractSDRs.openBladeRF(carrierFreq,samplingRate,gain)

@info "Initial config"
print(sdr)

##sleep(2)

@info "Update config"
AbstractSDRs.BladeRFBindings.updateCarrierFreq!(sdr,2400e6)
AbstractSDRs.BladeRFBindings.updateSamplingRate!(sdr,20e6)
AbstractSDRs.BladeRFBindings.updateRFBandwidth!(sdr,15e6)
AbstractSDRs.BladeRFBindings.updateGain!(sdr,15)

print(sdr)

close(sdr)


#ptr_bladerf = Ref{Ptr{C.bladerf}}()
#status = C.bladerf_open(ptr_bladerf,"")
#@info "Open BladeRF with status $status"

#@show theChannel = C.BLADERF_CHANNEL_RX(0)

#@info "status Carrier is $status"

#container = Ref{C.bladerf_sample_rate}(0)
#status = C.bladerf_set_sample_rate(ptr_bladerf[],theChannel,convert(C.bladerf_sample_rate,samplingRate),container)
#@info "status sampling is $status -> value $(container[])"


#container = Ref{C.bladerf_bandwidth}(0)
#status = C.bladerf_set_bandwidth(ptr_bladerf[],theChannel,convert(C.bladerf_bandwidth,gain),container)
#@info "status band is $status-> value $(container[])"

#status = C.bladerf_set_gain(ptr_bladerf[],theChannel,convert(C.bladerf_gain,gain))
#@info "status gain is $status"


 #C.bladerf_close(ptr_bladerf[])
