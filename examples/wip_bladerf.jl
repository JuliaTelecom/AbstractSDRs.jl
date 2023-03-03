using AbstractSDRs 


carrierFreq = 868e6 
samplingRate = 20e6 
gain = 12 


sdr = AbstractSDRs.openBladeRF(carrierFreq,samplingRate,gain)
