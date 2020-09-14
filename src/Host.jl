# uhdOverNetwork.jl 
# This module provides bind to monitor uhdOverNetwork based device from a Host PC
# As the uhdOverNetwork is a SoC based device with ARM, the Host <-> uhdOverNetwork link is assumed to be done with the use of sockets.
# With this module we construct utils to use the uhdOverNetwork device with same functions as it is a classic UHD device.

# This is quite similar with the uhd_network_mode with some important difference 
# - We use a specific communication system socket 
# - uhdOverNetwork side: a Julia script has to be launched. This script can also be modified to embed additional processing 

module Host

# --- Module dependency 
using Sockets 
using ZMQ
using Printf


# --- Method extension 
import Sockets:send;
import Sockets:recv;
import ZMQ:recv;
import ZMQ:send;
import ZMQ:close;
import Sockets:close;

# --- Symbol exportation 
export openUhdOverNetwork;
export openUhdOverNetworkRx;
export close;
export updateCarrierFreq!;
export updateSamplingRate!;
export updateGain!;
export recv;
export recv!;
export print;

struct SocketsuhdOverNetwork
    ip::IPAddr;
    rtcSocket::Socket;
    rttSocket::Socket;
    brSocket::Socket;
end
mutable struct Configuration
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Float64,Int};
	Antenna::String;
    packetSize::Int;
end
mutable struct MD
    intPart::Int32;
    fracPart::Cdouble;
	error::Int32;
end
mutable struct UHDOverNetwork 
    sockets::SocketsuhdOverNetwork;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
	antenna::String;
    packetSize::Csize_t;
    released::Int;
end
export UHDOverNetwork;


function initSockets(ip::String)
    e310Address  =  IPv4(ip);
    # --- Configuration Socket 
    # Socket used to send configuration and get configuration back 
    rtcSocket   = ZMQ.Socket(REQ);
    ZMQ.connect(rtcSocket,"tcp://$e310Address:5555");

    # --- Tx socket 
    # Socket used to transmit data from Host to e310 (Tx link)
    rttSocket = ZMQ.Socket(REQ);
    ZMQ.connect(rttSocket,"tcp://$e310Address:9999"); 

    # --- Rx socket 
    # Socket used for e310 to broacast Rx stream 
    brSocket    =  Socket(SUB);   # Define IPv4 adress 
    tcpSys		= string("tcp://$e310Address:1111");
    ZMQ.subscribe(brSocket);
    ZMQ.connect(brSocket,tcpSys);

    # --- Global socket packet
    sockets     = SocketsuhdOverNetwork(e310Address,rtcSocket,rttSocket,brSocket);
    return sockets
end

"""
Open a uhdOverNetwork remote device and initialize the sockets 
--- Syntax

openUhdOverNetwork(carrierFreq,samplingRate,gain,antenna="RX2";ip="192.168.10.11")
# --- Input parameters
- carrierFreq	: Desired Carrier frequency [Union{Int,Float64}] 
- samplingRate	: Desired bandwidth [Union{Int,Float64}] 
- gain		: Desired Rx Gain [Union{Int,Float64}] 
Keywords 
- ip	  : uhdOverNetwork IP address
- antenna		: Desired Antenna alias  (default "TX-RX") [String]
# --- Output parameters 
- structuhdOverNetwork    : Structure with uhdOverNetwork parameters [UHDOverNetwork]
"""
function openUhdOverNetwork(carrierFreq,samplingRate,gain;antenna="RX2",ip="192.168.10.11")
    # --- Create the Sockets 
    sockets = initSockets(ip);
    # --- Create the initial configuration based on input parameters 
    uhdOverNetwork    = UHDOverNetwork(
        sockets,
        carrierFreq,
        samplingRate,
        gain,
        antenna,
        0,
        0
    )
    # --- Update the radio based on input parameters 
    updateCarrierFreq!(uhdOverNetwork,carrierFreq);
    updateSamplingRate!(uhdOverNetwork,samplingRate);
    updateGain!(uhdOverNetwork,gain);
    # Get socket size 
    requestConfig!(uhdOverNetwork);
    # --- Print the configuration 
    print(uhdOverNetwork);
    # --- Return the final object
    return uhdOverNetwork;
end

function Base.close(uhdOverNetwork::UHDOverNetwork)
    # @info "coucou"
    # --- We close here all the related sockets
    close(uhdOverNetwork.sockets.rtcSocket);
    close(uhdOverNetwork.sockets.rttSocket);
    close(uhdOverNetwork.sockets.brSocket);
end

sendConfig(uhdOverNetwork::UHDOverNetwork,mess) = send(uhdOverNetwork.sockets.rtcSocket,mess)


function updateCarrierFreq!(uhdOverNetwork::UHDOverNetwork,carrierFreq)
    # --- Create char with command to be transmitted 
    # strF        = "global carrierFreq = $carrierFreq";
    strF        = "Dict(:updateCarrierFreq=>$carrierFreq);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    # --- Get the effective radio configuration 
    config = getuhdOverNetworkConfig(uhdOverNetwork);
    # --- Update the uhdOverNetwork object based on real radio config
    uhdOverNetwork.carrierFreq = config.carrierFreq;
    return uhdOverNetwork.carrierFreq;
end

function updateSamplingRate!(uhdOverNetwork::UHDOverNetwork,samplingRate)
    # --- Create char with command to be transmitted 
    strF        = "Dict(:updateSamplingRate=>$samplingRate);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    # --- Get the effective radio configuration 
    config = getuhdOverNetworkConfig(uhdOverNetwork);
    # --- Update the uhdOverNetwork object based on real radio config
    uhdOverNetwork.samplingRate = config.samplingRate;
    return uhdOverNetwork.samplingRate;
end

function updateGain!(uhdOverNetwork::UHDOverNetwork,gain)
    # --- Create char with command to be transmitted 
    strF        = "Dict(:updateGain=>$gain);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    # --- Get the effective radio configuration 
    config = getuhdOverNetworkConfig(uhdOverNetwork);
    # --- Update the uhdOverNetwork object based on real radio config
    uhdOverNetwork.gain = config.gain;
    return uhdOverNetwork.gain;
end


function requestConfig!(uhdOverNetwork::UHDOverNetwork);
    # --- Create char with command to be transmitted 
    strF        = "Dict(:requestConfig=>1);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    # --- Get the effective radio configuration 
    config = getuhdOverNetworkConfig(uhdOverNetwork);    
    uhdOverNetwork.packetSize = config.packetSize;
end

function recv(uhdOverNetwork::UHDOverNetwork,packetSize)
    # --- Create container 
    sig = Vector{Complex{Cfloat}}(undef,packetSize);
    # --- fill the stuff 
    recv!(sig,uhdOverNetwork);
    return sig;
end
function recv!(sig::Vector{Complex{Cfloat}},uhdOverNetwork::UHDOverNetwork;packetSize=0,offset=0)
	# --- Defined parameters for multiple buffer reception 
	filled		= false;
	# --- Fill the input buffer @ a specific offset 
	if offset == 0 
		posT		= 0;
	else 
		posT 		= offset;
	end
	# --- Managing desired size and buffer size
	if packetSize == 0
		# --- Fill all the buffer  
		packetSize	= length(sig);
	else 
		packetSize 	= packetSize;
		# --- Ensure that the allocation is possible
		@assert packetSize < (length(sig)+posT) "Impossible to fill the buffer (number of samples > residual size";
	end
	while !filled 
		# --- Get a buffer: We should have radio.packetSize or less 
		# radio.packetSize is the complex size, so x2
		(posT+uhdOverNetwork.packetSize> packetSize) ? n = packetSize - posT : n = uhdOverNetwork.packetSize;
        # --- UDP recv. This allocs. This is bad. No idea how to use prealloc pointer without rewriting the stack.
        tmp = reinterpret(Complex{Cfloat},recv(uhdOverNetwork.sockets.brSocket));
        sig[posT .+ (1:n)] .= @view tmp[1:n]; 
		# --- Update counters 
		posT += n; 
		# --- Breaking flag
		(posT == packetSize) ? filled = true : filled = false;
	end
	return posT
end

function getuhdOverNetworkConfig(uhdOverNetwork::UHDOverNetwork)
    receiver = recv(uhdOverNetwork.sockets.rtcSocket);
    res =  Meta.parse(String(receiver))
    config = eval(res);
    return Configuration(config...);
end

function Base.print(uhdOverNetwork::UHDOverNetwork)
    strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Rx Gain: %2.2f dB\n",uhdOverNetwork.carrierFreq/1e6,uhdOverNetwork.samplingRate/1e6,uhdOverNetwork.gain);
    @info "Current uhdOverNetwork Configuration in Rx mode\n$strF"; 
end


function getMD(uhdOverNetwork::UHDOverNetwork)
    # --- Create char with command to be transmitted 
    strF        = "Dict(:requestMD=>1);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    # --- Get the MD back 
    receiver = recv(uhdOverNetwork.sockets.rtcSocket);
    res =  Meta.parse(String(receiver))
    # --- Convert to a MD structure 
    md  = eval(res)
    return md;
end

end