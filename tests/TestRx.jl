module TestRx

using AbstractSDRs


function main()

    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 100e6;         # --- Targeted bandwdith 
    gain			= 0.0;         # --- Rx gain  
    ipAddr          = "192.168.10.11";
	sdr				= "UHDRx";
	nbSamples		= 1024;
    # --- Create the E310 device 
    # E310 = openE310("Rx",carrierFreq,samplingRate,gain;ip=ipAddr);
    E310 = openSDR(sdr,carrierFreq,samplingRate,gain;ip=ipAddr);
    print(E310);
    sleep(2);
    @info "Ready"
    updateCarrierFreq!(E310,770e6);
    print(E310);
    # 
    sig = recv(E310,nbSamples)
    # 
    close(E310);
end


end
