# --- USRP address 
global USRP_ADDRESS = "192.168.10.16"
#  This address may vary from time to time, not really sure how to handle dynamic testing 
#
#
# ----------------------------------------------------
# --- Define test routines 
# ---------------------------------------------------- 
"""
Scan with uhd_find_devices and return the USRP identifier 
"""
function check_scan()
    # --- First we use no parameter (broadcast ethernet link) 
    str = scan(:uhd)
    if length(str) == 0
        println("No UHD device found. Be sure that a USRP is connected to your PC, and that the ethernet link is up. We try to use the direct IP address now (which is $USRP_ADDRESS). You can change its value depending on your ethernet setup")
    else 
        # We find a device so we update the USRP address based on what we have found 
        global USRP_ADDRESS = str[1][findfirst("_addr=",str[1])[end] .+ (1:13)]
    end 
    # The direct call with the IP address should give something         
    str = uhd_find_devices("addr=$USRP_ADDRESS")
    @test length(str) > 0 
    return str
end

""" 
Test that the device can be open, configured and closed 
"""
function check_open()
    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    sdr				= :uhd
    # --- Create the device 
   global sdr = openSDR(sdr,carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
   # Type is OK 
   @test typeof(sdr) == UHDBinding
   # SDR is not released yet 
   @test isClosed(sdr) == false
   # Configuration : Carrier Freq 
   @test getCarrierFreq(sdr) == carrierFreq
   @test getCarrierFreq(sdr,mode=:rx) == carrierFreq
   @test getCarrierFreq(sdr,mode=:tx) == carrierFreq
   # Configuration : Badnwidth 
   @test getSamplingRate(sdr) == samplingRate
   @test getSamplingRate(sdr,mode=:rx) == samplingRate
   @test getSamplingRate(sdr,mode=:tx) == samplingRate
   # --- We close the SDR 
   close(sdr)
   @test isClosed(sdr) == true
end 

""" 
Check the carrier frequency update of the USRP device 
"""
function check_carrierFreq()
    # --- Main parameters 
    carrierFreq		= 440e6;	# --- The carrier frequency 	
    samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    # --- Create the device 
    sdr				= :uhd
    # --- Create the device 
   global sdr = openSDR(sdr,carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
   #  Classic value, should work 
   updateCarrierFreq!(sdr,800e6)
   @test getCarrierFreq(sdr) == 800e6
   @test getCarrierFreq(sdr,mode=:rx) == 800e6
   @test getCarrierFreq(sdr,mode=:tx) == 800e6
   # Targeting WiFi, should work
   updateCarrierFreq!(sdr,2400e6)
   @test getCarrierFreq(sdr) == 2400e6
   @test getCarrierFreq(sdr,mode=:rx) == 2400e6
   @test getCarrierFreq(sdr,mode=:tx) == 2400e6
   # If we specify a out of range frequency, it should bound to max val
   # TODO Check that is should be max freq range, but don't know the range as different USRP may be used
   # Adding tables with various ranges to check taht this is the expected value ?
   eF= updateCarrierFreq!(sdr,9e9)
   @test getCarrierFreq(sdr) != 9e9
   @test getCarrierFreq(sdr,mode=:rx) != 9e9
   @test getCarrierFreq(sdr,mode=:tx) != 9e9
   @test getCarrierFreq(sdr) == eF
   @test getCarrierFreq(sdr,mode=:rx) == eF
   @test getCarrierFreq(sdr,mode=:tx) == eF
   close(sdr);
   @test isClosed(sdr) == true
end

""" 
Check the sampling frequency update of the USRP device 
"""
function check_samplingRate()
    # --- Main parameters 
    carrierFreq		= 440e6;	# --- The carrier frequency 	
    samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    sdr				= :uhd
    # --- Create the device 
   global sdr = openSDR(sdr,carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
   #  Classic value, should work 
   updateSamplingRate!(sdr,8e6)
   @test getSamplingRate(sdr) == 8e6
   @test getSamplingRate(sdr,mode=:rx) == 8e6
   @test getSamplingRate(sdr,mode=:tx) == 8e6
   # Targeting WiFi, should work
   updateSamplingRate!(sdr,15.36e6)
   @test getSamplingRate(sdr) == 15.36e6
   @test getSamplingRate(sdr,mode=:rx) == 15.36e6
   @test getSamplingRate(sdr,mode=:tx) == 15.36e6
   # If we specify a out of range frequency, it should bound to max val
   eS = updateSamplingRate!(sdr,100e9)
   # @test getSamplingRate(sdr) != 100e9
   # @test getSamplingRate(sdr,mode=:rx) != 100e9 
   # @test getSamplingRate(sdr,mode=:tx) != 100e9 
   @test getSamplingRate(sdr) == eS
   @test getSamplingRate(sdr,mode=:rx) == eS 
   @test getSamplingRate(sdr,mode=:tx) == eS 
   close(sdr);
   @test isClosed(sdr) == true
end

""" 
Check the gain update for the USRP device
"""
function check_gain()
    # --- Main parameters 
    carrierFreq		= 440e6;	# --- The carrier frequency 	
    samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    sdr				= :uhd
    # --- Create the device 
   global sdr = openSDR(sdr,carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
   #  Classic value, should work 
   nG  = updateGain!(sdr,20)
   @test getGain(sdr) == 20
   @test getGain(sdr;mode=:rx) == 20
   @test getGain(sdr;mode=:tx) == 20
   @test getGain(sdr) == nG
   @test getGain(sdr;mode=:rx) == nG
   @test getGain(sdr;mode=:tx) == nG
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
    sdr				= :uhd
    # --- Create the device 
   global sdr = openSDR(sdr,carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
    sig = recv(sdr,1024)
    @test length(sig) == 1024 
    @test eltype(sig) == Complex{Float32}
    close(sdr)
    @test isClosed(sdr) == true
end 

""" 
Test that the device  can received data  with pre-allocation
"""
function check_recv_preAlloc()
    # --- Main parameters 
    carrierFreq		= 440e6;	# --- The carrier frequency 	
    samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    sdr				= :uhd
   global sdr = openUHD(carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
   sig = zeros(ComplexF32,2*1024)
   recv!(sig,sdr)
   @test length(sig) == 1024*2
   @test eltype(sig) == Complex{Float32}
   @test length(unique(sig)) > 1 # To be sure we have populated array with data
   close(sdr)
    @test isClosed(sdr) == true
end 

""" 
Test that the device can received data several time 
"""
function check_recv_iterative()
    # --- Main parameters 
    carrierFreq		= 440e6;	# --- The carrier frequency 	
    samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    # --- Create the device 
    sdr				= :uhd
   global sdr = openUHD(carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
   sig = zeros(ComplexF32,2*1024)
   nbPackets  = 0
   maxPackets = 100_000 
   for _ ∈ 1 : 1 : maxPackets
       # --- Get a burst 
       recv!(sig,sdr)
       # --- Increment packet index 
       nbPackets += 1
   end 
   @test nbPackets == maxPackets
   close(sdr)
   @test isClosed(sdr) == true
end 

"""
Test that the device sucessfully transmit data 
""" 
function check_send()
    carrierFreq		= 770e6;		
    samplingRate	= 4e6; 
    gain			= 50.0; 
    nbSamples		= 4096*2
    sdr				= :uhd
    # --- Create the device 
   global sdr = openSDR(sdr,carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
    print(sdr);
    # --- Create a sine wave
    f_c     = 3940;
    buffer  = 0.5.*[exp.(2im * π * f_c / samplingRate * n)  for n ∈ (0:nbSamples-1)];
    buffer  = convert.(Complex{Cfloat},buffer);

    buffer2  = 0.5.*[exp.(2im * π *  10 * f_c / samplingRate * n)  for n ∈ (0:nbSamples-1)];
    buffer2  = convert.(Complex{Cfloat},buffer2);
    buffer = [buffer;buffer2];

    cntAll  = 0;
    maxPackets = 10_000 
    nbPackets  = 0
    for _ ∈ 1 : maxPackets
        send(sdr,buffer,false);
       # --- Increment packet index 
       nbPackets += 1
    end
    @test nbPackets == maxPackets
    close(sdr)
   @test isClosed(sdr) == true
end

# # ----------------------------------------------------
# # --- Test calls
# # ---------------------------------------------------- 
# @testset "UHDBindings backend" begin 
# @testset "Scanning and opening" begin 
    # check_scan()
    # check_open()
# end 

# @testset "Radio configuration" begin 
    # check_carrierFreq()
    # check_samplingRate()
    # check_gain()
# end 

# @testset "Checking data retrieval"  begin 
    # check_recv()
    # check_recv_preAlloc()
    # check_recv_iterative()
# end

# @testset "Checking data transmission"  begin 
    # check_send()
# end
# end
