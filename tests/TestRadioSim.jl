module TestRadioSim 
using AbstractSDRs


function main()

    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 100e6;         # --- Targeted bandwdith 
    gain			= 0.0;         # --- Rx gain  
	sdr				= :radiosim;
	nbSamples		= 1024;
    # --- Create the E310 device 
    radio = openSDR(sdr,carrierFreq,samplingRate,gain;packetSize=512);
    print(radio);
    sleep(2);
    @info "Ready"
    updateCarrierFreq!(radio,770e6);
    print(radio);
    # 
    sig = recv(radio,nbSamples)
    # 
    close(radio);
end

function mainWithBuffer() 
    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 100e6;         # --- Targeted bandwdith 
    gain			= 0.0;         # --- Rx gain  
	sdr				= :radiosim;
	nbSamples		= 1024;
    # ----------------------------------------------------
    # --- Buffer emulation 
    # ---------------------------------------------------- 
    buffer = collect(1:4096);
    # --- Create the E310 device 
    radio = openSDR(sdr,carrierFreq,samplingRate,gain;packetSize=512,buffer=buffer);
    print(radio);
    sleep(2);
    # @info "Ready"
    updateCarrierFreq!(radio,770e6);
    print(radio);
    # 
    sig = recv(radio,nbSamples)
    sig .= 0
    sig = recv(radio,nbSamples)
    # 
    close(radio);
    return sig
end


function mainWithSmallBuffer() 
    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 100e6;         # --- Targeted bandwdith 
    gain			= 0.0;         # --- Rx gain  
	sdr				= :radiosim;
	nbSamples		= 1024;
    # ----------------------------------------------------
    # --- Buffer emulation 
    # ---------------------------------------------------- 
    buffer = collect(1:256);
    # --- Create the E310 device 
    radio = openSDR(sdr,carrierFreq,samplingRate,gain;packetSize=512,buffer=buffer);
    print(radio);
    sleep(2);
    # @info "Ready"
    updateCarrierFreq!(radio,770e6);
    print(radio);
    # 
    sig = recv(radio,nbSamples)
    sig .= 0
    sig = recv(radio,nbSamples)
    # 
    close(radio);
    return sig
end
end



