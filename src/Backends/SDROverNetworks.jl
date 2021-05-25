# uhdOverNetwork.jl 
# This module provides bind to monitor uhdOverNetwork based device from a Host PC
# As the uhdOverNetwork is a SoC based device with ARM, the Host <-> uhdOverNetwork link is assumed to be done with the use of sockets.
# With this module we construct utils to use the uhdOverNetwork device with same functions as it is a classic UHD device.

# This is quite similar with the uhd_network_mode with some important difference 
# - We use a specific communication system socket 
# - uhdOverNetwork side: a Julia script has to be launched. This script can also be modified to embed additional processing 

module SDROverNetworks

# --- Module dependency 
using Sockets 
using ZMQ
using Printf

# --- Print radio config
include("../Printing.jl");
using .Printing

# --- Method extension 
import Sockets:send;
import Sockets:recv;
import ZMQ:recv;
import ZMQ:send;
import ZMQ:close;
import Sockets:close;

# --- Symbol exportation 
export openUhdOverNetwork;
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
mutable struct SDROverNetworkRx 
    sockets::SocketsuhdOverNetwork;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
	antenna::String;
    packetSize::Csize_t;
    released::Int;
end
mutable struct SDROverNetworkTx 
    sockets::SocketsuhdOverNetwork;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
	antenna::String;
    packetSize::Csize_t;
    released::Int;
end
mutable struct SDROverNetwork
    radio::String;
    rx::SDROverNetworkRx;
    tx::SDROverNetworkTx;
end


export SDROverNetwork;


function initSockets(ip::String)
    # --- Format e310 IP address 
    e310Address  =  IPv4(ip);
    # --- Configuration Socket 
    # Socket used to send configuration and get configuration back 
    rtcSocket   = ZMQ.Socket(REQ);
    ZMQ.connect(rtcSocket,"tcp://$e310Address:5555");

    # --- Tx socket 
    # Socket used to transmit data from Host to e310 (Tx link)
    rttSocket = ZMQ.Socket(REP);
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
- structuhdOverNetwork    : Structure with uhdOverNetwork parameters [SDROverNetwork]
"""
function openUhdOverNetwork(carrierFreq,samplingRate,gain;antenna="RX2",addr="192.168.10.11")
    # --- Create the Sockets 
    sockets = initSockets(addr);
    # --- Create the initial configuration based on input parameters 
    rx    = SDROverNetworkRx(
        sockets,
        carrierFreq,
        samplingRate,
        gain,
        antenna,
        0,
        0
    );
    tx    = SDROverNetworkTx(
        sockets,
        carrierFreq,
        samplingRate,
        gain,
        antenna,
        0,
        0
    );
    # --- Instantiate the complete radio
    radio = SDROverNetwork(
                           addr,
                           rx,
                           tx
                          );
    # --- Update the radio based on input parameters 
    updateCarrierFreq!(radio,carrierFreq);
    updateSamplingRate!(radio,samplingRate);
    updateGain!(radio,gain);
    # Get socket size 
    requestConfig!(radio);
    # --- Print the configuration 
    print(radio);
    # --- Return the final object
    return radio;
end

function Base.close(radio::SDROverNetwork)
    # @info "coucou"
    # --- We close here all the related sockets
    close(radio.rx.sockets.rtcSocket);
    close(radio.rx.sockets.rttSocket);
    close(radio.rx.sockets.brSocket);
end

sendConfig(uhdOverNetwork::SDROverNetwork,mess) = send(uhdOverNetwork.rx.sockets.rtcSocket,mess)


function updateCarrierFreq!(uhdOverNetwork::SDROverNetwork,carrierFreq)
    # --- Create char with command to be transmitted 
    # strF        = "global carrierFreq = $carrierFreq";
    strF        = "Dict(:updateCarrierFreq=>$carrierFreq);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    # --- Get the effective radio configuration 
    config = getuhdOverNetworkConfig(uhdOverNetwork);
    # --- Update the uhdOverNetwork object based on real radio config
    uhdOverNetwork.rx.carrierFreq = config.carrierFreq;
    uhdOverNetwork.tx.carrierFreq = config.carrierFreq;
    return uhdOverNetwork.rx.carrierFreq;
end

function updateSamplingRate!(uhdOverNetwork::SDROverNetwork,samplingRate)
    # --- Create char with command to be transmitted 
    strF        = "Dict(:updateSamplingRate=>$samplingRate);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    # --- Get the effective radio configuration 
    config = getuhdOverNetworkConfig(uhdOverNetwork);
    # --- Update the uhdOverNetwork object based on real radio config
    uhdOverNetwork.rx.samplingRate = config.samplingRate;
    uhdOverNetwork.tx.samplingRate = config.samplingRate;
    return uhdOverNetwork.rx.samplingRate;
end

function updateGain!(uhdOverNetwork::SDROverNetwork,gain)
    # --- Create char with command to be transmitted 
    strF        = "Dict(:updateGain=>$gain);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    # --- Get the effective radio configuration 
    config = getuhdOverNetworkConfig(uhdOverNetwork);
    # --- Update the uhdOverNetwork object based on real radio config
    uhdOverNetwork.rx.gain = config.gain;
    uhdOverNetwork.tx.gain = config.gain;
    return uhdOverNetwork.rx.gain;
end


function requestConfig!(uhdOverNetwork::SDROverNetwork);
    # --- Create char with command to be transmitted 
    strF        = "Dict(:requestConfig=>1);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    # --- Get the effective radio configuration 
    config = getuhdOverNetworkConfig(uhdOverNetwork);    
    uhdOverNetwork.rx.packetSize = config.packetSize;
    uhdOverNetwork.tx.packetSize = config.packetSize;
end

function setRxMode(uhdOverNetwork::SDROverNetwork)
    # --- Create char with command to be transmitted 
    strF        = "Dict(:mode=>:rx);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    receiver = recv(uhdOverNetwork.rx.sockets.rtcSocket);
end
function recv(uhdOverNetwork::SDROverNetwork,packetSize)
    # --- Create container 
    sig = Vector{Complex{Cfloat}}(undef,packetSize);
    # --- fill the stuff 
    recv!(sig,uhdOverNetwork);
    return sig;
end
function recv!(sig::Vector{Complex{Cfloat}},uhdOverNetwork::SDROverNetwork;packetSize=0,offset=0)
    # setRxMode(uhdOverNetwork);
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
		(posT+uhdOverNetwork.rx.packetSize> packetSize) ? n = packetSize - posT : n = uhdOverNetwork.rx.packetSize;
        # --- UDP recv. This allocs. This is bad. No idea how to use prealloc pointer without rewriting the stack.
        tmp = reinterpret(Complex{Cfloat},recv(uhdOverNetwork.rx.sockets.brSocket));
        sig[posT .+ (1:n)] .= @view tmp[1:n]; 
		# --- Update counters 
		posT += n; 
		# --- Breaking flag
		(posT == packetSize) ? filled = true : filled = false;
	end
	return posT
end

#FIXME: We have setTxMode call before each Tx. Shall we do a setRxMode before each rx frame ?
function setTxMode(uhdOverNetwork::SDROverNetwork)
    # --- Create char with command to be transmitted 
    strF        = "Dict(:mode=>:tx);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    receiver = recv(uhdOverNetwork.rx.sockets.rtcSocket);
end
function setTxBufferMode(uhdOverNetwork::SDROverNetwork)
    # --- Create char with command to be transmitted 
    strF        = "Dict(:mode=>:txbuffer);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    receiver = recv(uhdOverNetwork.rx.sockets.rtcSocket);
end



function sendBuffer(buffer::Vector{Complex{Cfloat}},uhdOverNetwork::SDROverNetwork)
  # --- Create char with command to be transmitted 
    strF        = "Dict(:buffer:=>$buffer);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    config = getuhdOverNetworkConfig(uhdOverNetwork);    
    return config;
end



function send(sig::Vector{Complex{Cfloat}},uhdOverNetwork::SDROverNetwork,cyclic=false;maxNumSamp=nothing)
    # --- Setting radio in Tx mode 
    # setTxMode(uhdOverNetwork);
    nS  = 0;
    it  = length(sig);
    if cyclic == true 
        # ----------------------------------------------------
        # --- We handle Tx through metadata 
        # ---------------------------------------------------- 
        # setTxBufferMode(uhdOverNetwork):
        config = sendBuffer(sig,uhdOverNetwork);
    else
        # ----------------------------------------------------
        # --- Using RTT socket to handle data exchange
        # ---------------------------------------------------- 
        try 
            # --- First while loop is to handle cyclic transmission 
            # It turns to false in case of interruption or cyclic to false 
            while (true)
                # --- Wait for RTT
                rtt = ZMQ.recv(uhdOverNetwork.tx.sockets.rttSocket);
                # --- Sending data to Host 
                ZMQ.send(uhdOverNetwork.tx.sockets.rttSocket,sig);
                # --- Update counter 
                nS += it; 
                # --- Detection of cyclic mode 
                (maxNumSamp !== nothing && nS > maxNumSamp) && break
                (cyclic == false ) && break 
                # --- Forcing refresh
                yield();
            end 
        catch e;
            # --- Interruption handling
            print(e);
            print("\n");
            @info "Interruption detected";
            return 0;
        end
    end
    return nS;
end


function getuhdOverNetworkConfig(uhdOverNetwork::SDROverNetwork)
    receiver = recv(uhdOverNetwork.rx.sockets.rtcSocket);
    res =  Meta.parse(String(receiver))
    config = eval(res);
    return Configuration(config...);
end

function Base.print(uhdOverNetwork::SDROverNetwork)
    strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Rx Gain: %2.2f dB\n",uhdOverNetwork.rx.carrierFreq/1e6,uhdOverNetwork.rx.samplingRate/1e6,uhdOverNetwork.rx.gain);
    @inforx "Current uhdOverNetwork Configuration in Rx mode\n$strF"; 
    strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Rx Gain: %2.2f dB\n",uhdOverNetwork.tx.carrierFreq/1e6,uhdOverNetwork.tx.samplingRate/1e6,uhdOverNetwork.tx.gain);
    @infotx "Current uhdOverNetwork Configuration in Tx mode\n$strF"; 
end


function getMD(uhdOverNetwork::SDROverNetwork)
    # --- Create char with command to be transmitted 
    strF        = "Dict(:requestMD=>1);";
    # --- Send the command 
    sendConfig(uhdOverNetwork,strF);
    # --- Get the MD back 
    receiver = recv(uhdOverNetwork.rx.sockets.rtcSocket);
    res =  Meta.parse(String(receiver))
    # --- Convert to a MD structure 
    md  = eval(res)
    return md;
end


end
