# E310.jl 
# This module provides bind to monitor E310 based device from a Host PC
# As the E310 is a SoC based device with ARM, the Host <-> E310 link is assumed to be done with the use of sockets.
# With this module we construct utils to use the E310 device with same functions as it is a classic UHD device.

# This is quite similar with the uhd_network_mode with some important difference 
# - We use a specific communication system socket 
# - E310 side: a Julia script has to be launched. This script can also be modified to embed additional processing 

module HostE310 

# --- Module dependency 
using Sockets 
using Printf
# --- Symbol exportation 
export openE310;
export openE310Rx;
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
struct SocketsE310
    ip::IPAddr;
    data::CustomSockets;
    mdEH::CustomSockets;
    mdHE::CustomSockets;
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
mutable struct StructE310 
    sockets::SocketsE310;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
	antenna::String;
    packetSize::Csize_t;
    released::Int;
end
export StructE310;

"""
Open a E310 remote device and initialize the sockets 
--- Syntax

openE310(mode,carrierFreq,samplingRate,gain,antenna="RX2";ip="192.168.10.11")
# --- Input parameters
- mode : Mode for data exchange ("Tx" or "Rx") [String]
- carrierFreq	: Desired Carrier frequency [Union{Int,Float64}] 
- samplingRate	: Desired bandwidth [Union{Int,Float64}] 
- gain		: Desired Rx Gain [Union{Int,Float64}] 
Keywords 
- ip	  : E310 IP address
- antenna		: Desired Antenna alias  (default "TX-RX") [String]
# --- Output parameters 
- structE310    : Structure with E310 parameters [StructE310]
"""
function openE310(mode::String,carrierFreq,samplingRate,gain;antenna="RX2",ip="192.168.10.11")
    if lowercase(mode) == "rx"
        openE310Rx(carrierFreq,samplingRate,gain,antenna="RX2";ip="192.168.10.11")
    elseif lowercase(mode) == "rx"
        openE310Tx(carrierFreq,samplingRate,gain,antenna="TX/RX";ip="192.168.10.11")
    else 
        @error "Unknown mode for E310 configuration";
    end
end

function initSockets(ip::String)
    # Define IPv4 adress 
    # E310 side --> Used for HE link
    e310Adress  =  IPv4(ip);
    # Host adress --> Used for data and feedback
    hostAddress = IPv4("0.0.0.0");
    # --- Creates the MD socket 
    # To push config to E310 
    mdHESockets = UDPSocket();
    portHE      = 30000; 
    mdHE        = CustomSockets(mdHESockets,e310Adress,portHE);
    # To get config from E310 
    mdEHSockets = UDPSocket();
    portEH      = 36000;
    Sockets.bind(mdEHSockets,hostAddress,portEH,reuseaddr=true);
    mdEH        = CustomSockets(mdEHSockets,hostAddress,portEH);
    # Data socket 
    udpsock         = UDPSocket();
    Sockets.bind(udpsock,hostAddress,2001,reuseaddr=true);
    data        = CustomSockets(udpsock,hostAddress,2001);
    # Create the complete socket structure 
    sockets     = SocketsE310(hostAddress,data,mdEH,mdHE);
    return sockets
end


# --- Function definition 
function openE310Rx(carrierFreq,samplingRate,gain;antenna="RX2",ip="192.168.10.11")
    # --- Create the Sockets 
    sockets = initSockets(ip);
    # --- Create the initial configuration based on input parameters 
    E310    = StructE310(
        sockets,
        carrierFreq,
        samplingRate,
        gain,
        antenna,
        0,
        0
    )
    # --- Update the radio based on input parameters 
    updateCarrierFreq!(E310,carrierFreq);
    updateSamplingRate!(E310,samplingRate);
    updateGain!(E310,gain);
    # Get socket size 
    requestConfig!(E310);
    # --- Print the configuration 
    print(E310);
    # --- Return the final object
    return E310;
end

function Base.close(E310::StructE310)
    # --- We close here all the related sockets
    close(E310.sockets.data.socket);
    close(E310.sockets.mdEH.socket);
    close(E310.sockets.mdHE.socket);
end

function send(socket::CustomSockets,mess)
  Sockets.send(socket.socket,socket.ip,socket.port,mess);
end 
send(E310::StructE310,mess) = send(E310.sockets.mdHE,mess)


function updateCarrierFreq!(E310::StructE310,carrierFreq)
    # --- Create char with command to be transmitted 
    strF        = "global carrierFreq = $carrierFreq";
    # --- Send the command 
    send(E310,strF);
    # --- Get the effective radio configuration 
    config = getE310Config(E310);
    # --- Update the E310 object based on real radio config
    E310.carrierFreq = config.carrierFreq;
    return E310.carrierFreq;
end

function updateSamplingRate!(E310::StructE310,samplingRate)
    # --- Create char with command to be transmitted 
    strF        = "global samplingRate = $samplingRate";
    # --- Send the command 
    send(E310,strF);
    # --- Get the effective radio configuration 
    config = getE310Config(E310);
    # --- Update the E310 object based on real radio config
    E310.samplingRate = config.samplingRate;
    return E310.samplingRate;
end

function updateGain!(E310::StructE310,gain)
    # --- Create char with command to be transmitted 
    strF        = "global gain = $gain";
    # --- Send the command 
    send(E310,strF);
    # --- Get the effective radio configuration 
    config = getE310Config(E310);
    # --- Update the E310 object based on real radio config
    E310.gain = config.gain;
    return E310.gain;
end


function requestConfig!(E310::StructE310);
    # --- Create char with command to be transmitted 
    strF        = "requestConfig";
    # --- Send the command 
    send(E310,strF);
    # --- Get the effective radio configuration 
    config = getE310Config(E310);    
    E310.packetSize = config.packetSize;
end

function recv(E310::StructE310,packetSize)
    # --- Create container 
    sig = Vector{Complex{Cfloat}}(undef,packetSize);
    # --- fill the stuff 
    recv!(sig,E310);
    return sig;
end
function recv!(sig::Vector{Complex{Cfloat}},E310::StructE310;packetSize=0,offset=0)
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
		(posT+E310.packetSize> packetSize) ? n = packetSize - posT : n = E310.packetSize;
        # --- UDP recv. This allocs. This is bad. No idea how to use prealloc pointer without rewriting the stack.
        tmp = reinterpret(Complex{Cfloat},Sockets.recv(E310.sockets.data.socket));
        sig[posT .+ (1:n)] .= @view tmp[1:n]; 
		# --- Update counters 
		posT += n; 
		# --- Breaking flag
		(posT == packetSize) ? filled = true : filled = false;
	end
	return posT
end

function getE310Config(E310::StructE310)
    receiver = Sockets.recv(E310.sockets.mdEH.socket);
    res =  Meta.parse(String(receiver))
    config = eval(res);
    return Configuration(config...);
end

function Base.print(E310::StructE310)
    strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Rx Gain: %2.2f dB\n",E310.carrierFreq/1e6,E310.samplingRate/1e6,E310.gain);
    @info "Current E310 Configuration in Rx mode\n$strF"; 
end


function getMD(E310::StructE310)
    # --- Create char with command to be transmitted 
    strF        = "requestMD";
    # --- Send the command 
    send(E310,strF);
    # --- Get the MD back 
    receiver = Sockets.recv(E310.sockets.mdEH.socket);
    res =  Meta.parse(String(receiver))
    # --- Convert to a MD structure 
    md  = eval(res)
    return md;
end

end