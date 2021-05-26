# ----------------------------------------------------
# --- Radio Sim test file 
# ---------------------------------------------------- 
# This file is dedicated to RadioSim backend

# ----------------------------------------------------
# --- Define test routines 
# ---------------------------------------------------- 

""" 
Test that the device can be open, configured and closed 
"""
function check_open()
    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
	sdr				= :radiosim
    # --- Create the E310 device 
   global sdr =openSDR(sdr,carrierFreq,samplingRate,gain);
   # Type is OK 
   @test typeof(sdr) == RadioSim 
   # SDR is not released yet 
   @test sdr.rx.released == false
   # Configuration : Carrier Freq 
   @test sdr.rx.carrierFreq == carrierFreq
   @test sdr.tx.carrierFreq == carrierFreq
   # Configuration : Badnwidth 
   @test sdr.rx.samplingRate == samplingRate
   @test sdr.tx.samplingRate == samplingRate
   # --- We close the SDR 
   close(sdr)
   @test isClosed(sdr) == true
end 

""" 
Check the carrier frequency update of the RadioSim device 
"""
function check_carrierFreq()
    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
	sdr				= :radiosim
    # --- Create the E310 device 
   global sdr =openSDR(sdr,carrierFreq,samplingRate,gain);
   #  Classic value, should work 
   updateCarrierFreq!(sdr,800e6)
   @test sdr.rx.carrierFreq == 800e6
   @test sdr.tx.carrierFreq == 800e6
   # Targeting WiFi, should work
   updateCarrierFreq!(sdr,2400e6)
   @test sdr.rx.carrierFreq == 2400e6
   @test sdr.tx.carrierFreq == 2400e6
   close(sdr);
   @test isClosed(sdr) == true
end

""" 
Check the sampling frequency update of the RadioSim device 
"""
function check_samplingRate()
    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
	sdr				= :radiosim
    # --- Create the E310 device 
   global sdr =openSDR(sdr,carrierFreq,samplingRate,gain);
   #  Classic value, should work 
   updateSamplingRate!(sdr,8e6)
   @test sdr.rx.samplingRate == 8e6
   @test sdr.tx.samplingRate == 8e6
   # Targeting WiFi, should work
   updateSamplingRate!(sdr,15.36e6)
   @test sdr.rx.samplingRate == 15.36e6
   @test sdr.tx.samplingRate == 15.36e6
   close(sdr);
   @test isClosed(sdr) == true
end

""" 
Check the gain update for RadioSim 
"""
function check_gain()
    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
	sdr				= :radiosim
    # --- Create the E310 device 
   global sdr =openSDR(sdr,carrierFreq,samplingRate,gain);
   #  Classic value, should work 
   updateGain!(sdr,20)
   # @test sdr.rx.samplingRate == 8e6
   # @test sdr.tx.samplingRate == 8e6
   close(sdr);
   @test isClosed(sdr) == true
end 


""" 
Test that the device  can received data 
"""
function check_recv()
    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
	sdr				= :radiosim
    # --- Create the E310 device 
    global sdr =openSDR(sdr,carrierFreq,samplingRate,gain);
    sig = recv(sdr,1024)
    @test length(sig) == 1024 
    @test eltype(sig) == Complex{Float32}
    close(sdr)
    @test isClosed(sdr) == true
end 


""" 
Test that radiosim device can feed desired data 
""" 
function check_recv_prealloc()
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
    global sdr =openSDR(sdr,carrierFreq,samplingRate,gain;packetSize=512,buffer=buffer);
    sig = recv(sdr,1024)
    @test length(sig) == 1024 
    @test eltype(sig) == Complex{Float32}
    # The first call should give the 1024 fist samples 
    @test all(sig .== collect(1:1024))
    # --- Second call give second part 
    sig = recv(sdr,1024)
    @test length(sig) == 1024 
    @test eltype(sig) == Complex{Float32}
    @test all(sig .== collect(1025:2048))
    # --- Third call to have the end 
    sig = recv(sdr,2048)
    @test length(sig) == 2048
    @test eltype(sig) == Complex{Float32}
    @test all(sig .== collect(2049:4096))
    # --- Another complete call with complete buffer 
    sig = recv(sdr,4096)
    @test length(sig) == 4096 
    @test eltype(sig) == Complex{Float32}
    @test all(sig .== buffer)
    # --- Close radio
    close(sdr)
    @test isClosed(sdr) == true
end


# ----------------------------------------------------
# --- Test calls
# ---------------------------------------------------- 
@testset "RadioSims Backend " begin 
    @testset "Scanning and opening" begin 
        check_open()
    end 

    @testset "Radio configuration" begin 
        check_carrierFreq()
        check_samplingRate()
        check_gain()
    end 

    @testset "Checking data retrieval"  begin 
        check_recv()
        check_recv_prealloc()
    end
end
