
using AbstractSDRs



    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 4e6;         # --- Targeted bandwdith 
    gain			= 0.0;         # --- Rx gain  
    ipAddr          = "192.168.10.12";
	nbSamples		= 2048;
    # --- Create the E310 device 
    # E310 = openE310("Rx",carrierFreq,samplingRate,gain;ip=ipAddr);
    E310 = openSDR("E310",carrierFreq,samplingRate,gain;ip=ipAddr);
    print(E310);
    sleep(2);
    @info "Ready"
    updateCarrierFreq!(E310,770e6);
    print(E310);
    # 
    sig = recv(E310,nbSamples)
    @show size(sig);
    @show getError(E310)
    @show getTimestamp(E310)
    # 
    # close(E310);
