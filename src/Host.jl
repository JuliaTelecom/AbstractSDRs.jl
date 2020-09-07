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

# --- Structure configuration 
struct CustomSockets
    socket::UDPSocket;
    ip::IPAddr;
    port::Int;
end
struct CustomZMQ 
    socket::Socket;
    ip::IPAddr;
    port::Int;
end


struct SocketsuhdOverNetwork
    ip::IPAddr;
    data::CustomZMQ;
    mdEH::CustomZMQ;
    mdHE::CustomZMQ;
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
    # Define IPv4 adress 
    # uhdOverNetwork side --> Used for HE link
    e310Adress  =  IPv4(ip);
    # Host adress --> Used for data and feedback
    hostAddress = IPv4("0.0.0.0");
    # --- Creates the MD socket 
    # To push config to uhdOverNetwork 
    # TODO: => Switch the UDP socket for config push to ZMQ 
    mdHESockets = ZMQ.Socket(PUB)
    bind(mdHESockets,"tcp://*:55555");
    mdHE        = CustomZMQ(mdHESockets,e310Adress,55555)
    # To get config from uhdOverNetwork 
    mdEHSockets = Socket(SUB);
    tcpSys		 = string("tcp://$e310Adress:30000");
    ZMQ.subscribe(mdEHSockets);
    ZMQ.connect(mdEHSockets,tcpSys);
    mdEH = CustomZMQ(mdEHSockets,e310Adress,30000);
    # Rx Data socket 
    zmqSock     = Socket(SUB);
    tcpSys		 = string("tcp://$e310Adress:9999");
    ZMQ.subscribe(zmqSock);
    ZMQ.connect(zmqSock,tcpSys);
    data = CustomZMQ(zmqSock,e310Adress,9999);
    # Request To Receive (RTR) socket
    rtrSock     = Socket(SUB);
    tcpSys		 = string("tcp://$e310Adress:5555");
    ZMQ.subscribe(rtrSock);
    ZMQ.connect(rtrSock,tcpSys);
    rtr = CustomZMQ(rtrSock,e310Adress,5555);
    # Tx data socket 
    # TODO: => Create ZMQ socket for data push
    # ---  Connect to socket
    # --- Global socket packet
    sockets     = SocketsuhdOverNetwork(hostAddress,data,mdEH,mdHE);
    @info "1"
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
    # --- We close here all the related sockets
    close(uhdOverNetwork.sockets.data.socket);
    close(uhdOverNetwork.sockets.mdEH.socket);
    close(uhdOverNetwork.sockets.mdHE.socket);
end

function send(socket::CustomSockets,mess)
  Sockets.send(socket.socket,socket.ip,socket.port,mess);
end 
function send(socket::CustomZMQ,mess)
    ZMQ.send(socket.socket,mess);
end
send(uhdOverNetwork::UHDOverNetwork,mess) = send(uhdOverNetwork.sockets.mdHE,mess)


function updateCarrierFreq!(uhdOverNetwork::UHDOverNetwork,carrierFreq)
    # --- Create char with command to be transmitted 
    # strF        = "global carrierFreq = $carrierFreq";
    strF        = "Dict(:updateCarrierFreq=>$carrierFreq);";
    # --- Send the command 
    send(uhdOverNetwork,strF);
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
    send(uhdOverNetwork,strF);
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
    send(uhdOverNetwork,strF);
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
    send(uhdOverNetwork,strF);
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
        tmp = reinterpret(Complex{Cfloat},ZMQ.recv(uhdOverNetwork.sockets.data.socket));
        sig[posT .+ (1:n)] .= @view tmp[1:n]; 
		# --- Update counters 
		posT += n; 
		# --- Breaking flag
		(posT == packetSize) ? filled = true : filled = false;
	end
	return posT
end

function getuhdOverNetworkConfig(uhdOverNetwork::UHDOverNetwork)
    receiver = ZMQ.recv(uhdOverNetwork.sockets.mdEH.socket);
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
    send(uhdOverNetwork,strF);
    # --- Get the MD back 
    receiver = ZMQ.recv(uhdOverNetwork.sockets.mdEH.socket);
    res =  Meta.parse(String(receiver))
    # --- Convert to a MD structure 
    md  = eval(res)
    return md;
end

end