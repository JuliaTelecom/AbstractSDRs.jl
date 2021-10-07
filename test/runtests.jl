# Testing SDR backends 
using Test 
using AbstractSDRs

# ----------------------------------------------------
# --- Testing radioSim back end 
# ---------------------------------------------------- 
# This backend requires no SDR connected so we can use it by default 
# Most of the test are also sone in the comon API call but set a specific test call here 
# to test everything is OK on the API side and that specific RadioSim properties are OK (especially control that emulated received data is the one desired)
include("test_RadioSim.jl")


# ----------------------------------------------------
# --- Test functions 
# ---------------------------------------------------- 
# Define here key behaviour common for all radio 
# You can have a look here to find pratical examples of radio use
include("test_functions.jl")


# ----------------------------------------------------
# --- Common API call for all backend 
# ---------------------------------------------------- 
# Issue is that we need a connected device to perform all test so we will do as follows 
# => Try to scan for device. If detected then proceed to the test, otherwise drop the test 
# For UHD, we need to hardcode a potential IP address in case of non broadcast ehternet address. If we detect the UHD device with scan(:uhd) the we use the associated IP address. Otherwise we use UHD_ADDRESS. It means that in case of non broadcast ethernet link, you should modify the following line according to your UHD IP address
# --- USRP address 
global UHD_ADDRESS = "192.168.10.16"
#  This address may vary from time to time, not really sure how to handle dynamic testing 


# --- Define test backend 
backends = [:radiosim;:uhd;:pluto]
backends = [:radiosim;:pluto]
for sdr ∈ backends 
    # --- Flaging test
    println("######################################")
    println("# --- Testing $sdr backend ---")
    println("######################################")
    # --- Test scan 
    str = scan(sdr)
    if isempty(str)
        println("No device found, rescan with IP address $UHD_ADDRESS")
        # If we have nothing, try with the USRP address
        str = scan(sdr;args="addr=$UHD_ADDRESS")
    end
    if isempty(str)
        # ----------------------------------------------------
        # --- We have find nothing, drop the rest of the tests 
        # ---------------------------------------------------- 
        @warn "Unable to detect any SDR devices based on backend $sdr\n Abandon rest of tests"
    else
        # For UHD, we update str to be sure we can use the SDR latter on
        global UHD_ADDRESS = str[1]
        # ----------------------------------------------------
        # --- Testing stuff 
        # ---------------------------------------------------- 
        @testset "Opening" begin 
            # check_scan(sdr;UHD_ADDRESS)
            check_open(sdr)
        end 

        @testset "Radio configuration" begin 
            check_carrierFreq(sdr)
            check_samplingRate(sdr)
            check_gain(sdr)
        end 

        @testset "Checking data retrieval"  begin 
            check_recv(sdr)
            check_recv_preAlloc(sdr)
            check_recv_iterative(sdr)
        end

        @testset "Checking data transmission"  begin 
            check_send(sdr)
        end
    end
end
