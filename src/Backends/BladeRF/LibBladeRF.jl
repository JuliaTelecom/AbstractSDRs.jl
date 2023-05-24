module LibBladeRF 


using BladeRFHardwareDriver_jll
#export BladeRFHardwareDriver_jll

using CEnum

@cenum bladerf_lna_gain::UInt32 begin
    BLADERF_LNA_GAIN_UNKNOWN = 0
    BLADERF_LNA_GAIN_BYPASS = 1
    BLADERF_LNA_GAIN_MID = 2
    BLADERF_LNA_GAIN_MAX = 3
end

@cenum bladerf_sampling::UInt32 begin
    BLADERF_SAMPLING_UNKNOWN = 0
    BLADERF_SAMPLING_INTERNAL = 1
    BLADERF_SAMPLING_EXTERNAL = 2
end

@cenum bladerf_lpf_mode::UInt32 begin
    BLADERF_LPF_NORMAL = 0
    BLADERF_LPF_BYPASSED = 1
    BLADERF_LPF_DISABLED = 2
end

@cenum bladerf_smb_mode::Int32 begin
    BLADERF_SMB_MODE_INVALID = -1
    BLADERF_SMB_MODE_DISABLED = 0
    BLADERF_SMB_MODE_OUTPUT = 1
    BLADERF_SMB_MODE_INPUT = 2
    BLADERF_SMB_MODE_UNAVAILBLE = 3
end

@cenum bladerf_xb200_filter::UInt32 begin
    BLADERF_XB200_50M = 0
    BLADERF_XB200_144M = 1
    BLADERF_XB200_222M = 2
    BLADERF_XB200_CUSTOM = 3
    BLADERF_XB200_AUTO_1DB = 4
    BLADERF_XB200_AUTO_3DB = 5
end

@cenum bladerf_xb200_path::UInt32 begin
    BLADERF_XB200_BYPASS = 0
    BLADERF_XB200_MIX = 1
end

@cenum bladerf_xb300_trx::Int32 begin
    BLADERF_XB300_TRX_INVAL = -1
    BLADERF_XB300_TRX_TX = 0
    BLADERF_XB300_TRX_RX = 1
    BLADERF_XB300_TRX_UNSET = 2
end

@cenum bladerf_xb300_amplifier::Int32 begin
    BLADERF_XB300_AMP_INVAL = -1
    BLADERF_XB300_AMP_PA = 0
    BLADERF_XB300_AMP_LNA = 1
    BLADERF_XB300_AMP_PA_AUX = 2
end

@cenum bladerf_cal_module::Int32 begin
    BLADERF_DC_CAL_INVALID = -1
    BLADERF_DC_CAL_LPF_TUNING = 0
    BLADERF_DC_CAL_TX_LPF = 1
    BLADERF_DC_CAL_RX_LPF = 2
    BLADERF_DC_CAL_RXVGA2 = 3
end

struct bladerf_lms_dc_cals
    lpf_tuning::Cint
    tx_lpf_i::Cint
    tx_lpf_q::Cint
    rx_lpf_i::Cint
    rx_lpf_q::Cint
    dc_ref::Cint
    rxvga2a_i::Cint
    rxvga2a_q::Cint
    rxvga2b_i::Cint
    rxvga2b_q::Cint
end

@cenum bladerf_rfic_rxfir::UInt32 begin
    BLADERF_RFIC_RXFIR_BYPASS = 0
    BLADERF_RFIC_RXFIR_CUSTOM = 1
    BLADERF_RFIC_RXFIR_DEC1 = 2
    BLADERF_RFIC_RXFIR_DEC2 = 3
    BLADERF_RFIC_RXFIR_DEC4 = 4
end

@cenum bladerf_rfic_txfir::UInt32 begin
    BLADERF_RFIC_TXFIR_BYPASS = 0
    BLADERF_RFIC_TXFIR_CUSTOM = 1
    BLADERF_RFIC_TXFIR_INT1 = 2
    BLADERF_RFIC_TXFIR_INT2 = 3
    BLADERF_RFIC_TXFIR_INT4 = 4
end

@cenum bladerf_power_sources::UInt32 begin
    BLADERF_UNKNOWN = 0
    BLADERF_PS_DC = 1
    BLADERF_PS_USB_VBUS = 2
end

@cenum bladerf_clock_select::UInt32 begin
    CLOCK_SELECT_ONBOARD = 0
    CLOCK_SELECT_EXTERNAL = 1
end

@cenum bladerf_pmic_register::UInt32 begin
    BLADERF_PMIC_CONFIGURATION = 0
    BLADERF_PMIC_VOLTAGE_SHUNT = 1
    BLADERF_PMIC_VOLTAGE_BUS = 2
    BLADERF_PMIC_POWER = 3
    BLADERF_PMIC_CURRENT = 4
    BLADERF_PMIC_CALIBRATION = 5
end

struct bladerf_rf_switch_config
    tx1_rfic_port::Cint
    tx1_spdt_port::Cint
    tx2_rfic_port::Cint
    tx2_spdt_port::Cint
    rx1_rfic_port::Cint
    rx1_spdt_port::Cint
    rx2_rfic_port::Cint
    rx2_spdt_port::Cint
end

const bladerf_channel = Cint

const bladerf_timestamp = UInt64

mutable struct bladerf end

@cenum bladerf_backend::UInt32 begin
    BLADERF_BACKEND_ANY = 0
    BLADERF_BACKEND_LINUX = 1
    BLADERF_BACKEND_LIBUSB = 2
    BLADERF_BACKEND_CYPRESS = 3
    BLADERF_BACKEND_DUMMY = 100
end

struct bladerf_devinfo
    backend::bladerf_backend
    serial::NTuple{33, Cchar}
    usb_bus::UInt8
    usb_addr::UInt8
    instance::Cuint
    manufacturer::NTuple{33, Cchar}
    product::NTuple{33, Cchar}
end

struct bladerf_backendinfo
    handle_count::Cint
    handle::Ptr{Cvoid}
    lock_count::Cint
    lock::Ptr{Cvoid}
end


## Anonylous functions 
BLADERF_XB_GPIO(n)  = (1 << (n - 1))
BLADERF_CHANNEL_RX(ch) = ((ch << 1) | 0x0)
BLADERF_CHANNEL_TX(ch) = ((ch << 1) | 0x1)


function bladerf_open(device, device_identifier)
    ccall((:bladerf_open, libbladerf), Cint, (Ptr{Ptr{bladerf}}, Ptr{Cchar}), device, device_identifier)
end

function bladerf_close(device)
    ccall((:bladerf_close, libbladerf), Cvoid, (Ptr{bladerf},), device)
end

function bladerf_open_with_devinfo(device, devinfo)
    ccall((:bladerf_open_with_devinfo, libbladerf), Cint, (Ptr{Ptr{bladerf}}, Ptr{bladerf_devinfo}), device, devinfo)
end

function bladerf_get_device_list(devices)
    ccall((:bladerf_get_device_list, libbladerf), Cint, (Ptr{Ptr{bladerf_devinfo}},), devices)
end

function bladerf_free_device_list(devices)
    ccall((:bladerf_free_device_list, libbladerf), Cvoid, (Ptr{bladerf_devinfo},), devices)
end

function bladerf_init_devinfo(info)
    ccall((:bladerf_init_devinfo, libbladerf), Cvoid, (Ptr{bladerf_devinfo},), info)
end

function bladerf_get_devinfo(dev, info)
    ccall((:bladerf_get_devinfo, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_devinfo}), dev, info)
end

function bladerf_get_backendinfo(dev, info)
    ccall((:bladerf_get_backendinfo, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_backendinfo}), dev, info)
end

function bladerf_get_devinfo_from_str(devstr, info)
    ccall((:bladerf_get_devinfo_from_str, libbladerf), Cint, (Ptr{Cchar}, Ptr{bladerf_devinfo}), devstr, info)
end

function bladerf_devinfo_matches(a, b)
    ccall((:bladerf_devinfo_matches, libbladerf), Bool, (Ptr{bladerf_devinfo}, Ptr{bladerf_devinfo}), a, b)
end

function bladerf_devstr_matches(dev_str, info)
    ccall((:bladerf_devstr_matches, libbladerf), Bool, (Ptr{Cchar}, Ptr{bladerf_devinfo}), dev_str, info)
end

function bladerf_backend_str(backend)
    ccall((:bladerf_backend_str, libbladerf), Ptr{Cchar}, (bladerf_backend,), backend)
end

function bladerf_set_usb_reset_on_open(enabled)
    ccall((:bladerf_set_usb_reset_on_open, libbladerf), Cvoid, (Bool,), enabled)
end

struct bladerf_range
    min::Int64
    max::Int64
    step::Int64
    scale::Cfloat
end

struct bladerf_serial
    serial::NTuple{33, Cchar}
end

struct bladerf_version
    major::UInt16
    minor::UInt16
    patch::UInt16
    describe::Ptr{Cchar}
end

@cenum bladerf_fpga_size::UInt32 begin
    BLADERF_FPGA_UNKNOWN = 0
    BLADERF_FPGA_40KLE = 40
    BLADERF_FPGA_115KLE = 115
    BLADERF_FPGA_A4 = 49
    BLADERF_FPGA_A5 = 77
    BLADERF_FPGA_A9 = 301
end

@cenum bladerf_dev_speed::UInt32 begin
    BLADERF_DEVICE_SPEED_UNKNOWN = 0
    BLADERF_DEVICE_SPEED_HIGH = 1
    BLADERF_DEVICE_SPEED_SUPER = 2
end

@cenum bladerf_fpga_source::UInt32 begin
    BLADERF_FPGA_SOURCE_UNKNOWN = 0
    BLADERF_FPGA_SOURCE_FLASH = 1
    BLADERF_FPGA_SOURCE_HOST = 2
end

function bladerf_get_serial(dev, serial)
    ccall((:bladerf_get_serial, libbladerf), Cint, (Ptr{bladerf}, Ptr{Cchar}), dev, serial)
end

function bladerf_get_serial_struct(dev, serial)
    ccall((:bladerf_get_serial_struct, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_serial}), dev, serial)
end

function bladerf_get_fpga_size(dev, size)
    ccall((:bladerf_get_fpga_size, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_fpga_size}), dev, size)
end

function bladerf_get_fpga_bytes(dev, size)
    ccall((:bladerf_get_fpga_bytes, libbladerf), Cint, (Ptr{bladerf}, Ptr{Csize_t}), dev, size)
end

function bladerf_get_flash_size(dev, size, is_guess)
    ccall((:bladerf_get_flash_size, libbladerf), Cint, (Ptr{bladerf}, Ptr{UInt32}, Ptr{Bool}), dev, size, is_guess)
end

function bladerf_fw_version(dev, version)
    ccall((:bladerf_fw_version, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_version}), dev, version)
end

function bladerf_is_fpga_configured(dev)
    ccall((:bladerf_is_fpga_configured, libbladerf), Cint, (Ptr{bladerf},), dev)
end

function bladerf_fpga_version(dev, version)
    ccall((:bladerf_fpga_version, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_version}), dev, version)
end

function bladerf_get_fpga_source(dev, source)
    ccall((:bladerf_get_fpga_source, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_fpga_source}), dev, source)
end

function bladerf_device_speed(dev)
    ccall((:bladerf_device_speed, libbladerf), bladerf_dev_speed, (Ptr{bladerf},), dev)
end

function bladerf_get_board_name(dev)
    ccall((:bladerf_get_board_name, libbladerf), Ptr{Cchar}, (Ptr{bladerf},), dev)
end

const bladerf_module = bladerf_channel

@cenum bladerf_direction::UInt32 begin
    BLADERF_RX = 0
    BLADERF_TX = 1
end

@cenum bladerf_channel_layout::UInt32 begin
    BLADERF_RX_X1 = 0
    BLADERF_TX_X1 = 1
    BLADERF_RX_X2 = 2
    BLADERF_TX_X2 = 3
end

function bladerf_get_channel_count(dev, dir)
    ccall((:bladerf_get_channel_count, libbladerf), Csize_t, (Ptr{bladerf}, bladerf_direction), dev, dir)
end

const bladerf_gain = Cint

@cenum bladerf_gain_mode::UInt32 begin
    BLADERF_GAIN_DEFAULT = 0
    BLADERF_GAIN_MGC = 1
    BLADERF_GAIN_FASTATTACK_AGC = 2
    BLADERF_GAIN_SLOWATTACK_AGC = 3
    BLADERF_GAIN_HYBRID_AGC = 4
end

struct bladerf_gain_modes
    name::Ptr{Cchar}
    mode::bladerf_gain_mode
end

function bladerf_set_gain(dev, ch, gain)
    ccall((:bladerf_set_gain, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, bladerf_gain), dev, ch, gain)
end

function bladerf_get_gain(dev, ch, gain)
    ccall((:bladerf_get_gain, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{bladerf_gain}), dev, ch, gain)
end

function bladerf_set_gain_mode(dev, ch, mode)
    ccall((:bladerf_set_gain_mode, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, bladerf_gain_mode), dev, ch, mode)
end

function bladerf_get_gain_mode(dev, ch, mode)
    ccall((:bladerf_get_gain_mode, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{bladerf_gain_mode}), dev, ch, mode)
end

function bladerf_get_gain_modes(dev, ch, modes)
    ccall((:bladerf_get_gain_modes, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{Ptr{bladerf_gain_modes}}), dev, ch, modes)
end

function bladerf_get_gain_range(dev, ch, range)
    ccall((:bladerf_get_gain_range, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{Ptr{bladerf_range}}), dev, ch, range)
end

function bladerf_set_gain_stage(dev, ch, stage, gain)
    ccall((:bladerf_set_gain_stage, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{Cchar}, bladerf_gain), dev, ch, stage, gain)
end

function bladerf_get_gain_stage(dev, ch, stage, gain)
    ccall((:bladerf_get_gain_stage, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{Cchar}, Ptr{bladerf_gain}), dev, ch, stage, gain)
end

function bladerf_get_gain_stage_range(dev, ch, stage, range)
    ccall((:bladerf_get_gain_stage_range, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{Cchar}, Ptr{Ptr{bladerf_range}}), dev, ch, stage, range)
end

function bladerf_get_gain_stages(dev, ch, stages, count)
    ccall((:bladerf_get_gain_stages, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{Ptr{Cchar}}, Csize_t), dev, ch, stages, count)
end

const bladerf_sample_rate = Cuint

struct bladerf_rational_rate
    integer::UInt64
    num::UInt64
    den::UInt64
end

function bladerf_set_sample_rate(dev, ch, rate, actual)
    ccall((:bladerf_set_sample_rate, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, bladerf_sample_rate, Ptr{bladerf_sample_rate}), dev, ch, rate, actual)
end

function bladerf_set_rational_sample_rate(dev, ch, rate, actual)
    ccall((:bladerf_set_rational_sample_rate, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{bladerf_rational_rate}, Ptr{bladerf_rational_rate}), dev, ch, rate, actual)
end

function bladerf_get_sample_rate(dev, ch, rate)
    ccall((:bladerf_get_sample_rate, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{bladerf_sample_rate}), dev, ch, rate)
end

function bladerf_get_sample_rate_range(dev, ch, range)
    ccall((:bladerf_get_sample_rate_range, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{Ptr{bladerf_range}}), dev, ch, range)
end

function bladerf_get_rational_sample_rate(dev, ch, rate)
    ccall((:bladerf_get_rational_sample_rate, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{bladerf_rational_rate}), dev, ch, rate)
end

const bladerf_bandwidth = Cuint

function bladerf_set_bandwidth(dev, ch, bandwidth, actual)
    ccall((:bladerf_set_bandwidth, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, bladerf_bandwidth, Ptr{bladerf_bandwidth}), dev, ch, bandwidth, actual)
end

function bladerf_get_bandwidth(dev, ch, bandwidth)
    ccall((:bladerf_get_bandwidth, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{bladerf_bandwidth}), dev, ch, bandwidth)
end

function bladerf_get_bandwidth_range(dev, ch, range)
    ccall((:bladerf_get_bandwidth_range, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{Ptr{bladerf_range}}), dev, ch, range)
end

const bladerf_frequency = UInt64

function bladerf_select_band(dev, ch, frequency)
    ccall((:bladerf_select_band, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, bladerf_frequency), dev, ch, frequency)
end

function bladerf_set_frequency(dev, ch, frequency)
    ccall((:bladerf_set_frequency, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, bladerf_frequency), dev, ch, frequency)
end

function bladerf_get_frequency(dev, ch, frequency)
    ccall((:bladerf_get_frequency, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{bladerf_frequency}), dev, ch, frequency)
end

function bladerf_get_frequency_range(dev, ch, range)
    ccall((:bladerf_get_frequency_range, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{Ptr{bladerf_range}}), dev, ch, range)
end

@cenum bladerf_loopback::UInt32 begin
    BLADERF_LB_NONE = 0
    BLADERF_LB_FIRMWARE = 1
    BLADERF_LB_BB_TXLPF_RXVGA2 = 2
    BLADERF_LB_BB_TXVGA1_RXVGA2 = 3
    BLADERF_LB_BB_TXLPF_RXLPF = 4
    BLADERF_LB_BB_TXVGA1_RXLPF = 5
    BLADERF_LB_RF_LNA1 = 6
    BLADERF_LB_RF_LNA2 = 7
    BLADERF_LB_RF_LNA3 = 8
    BLADERF_LB_RFIC_BIST = 9
end

struct bladerf_loopback_modes
    name::Ptr{Cchar}
    mode::bladerf_loopback
end

function bladerf_get_loopback_modes(dev, modes)
    ccall((:bladerf_get_loopback_modes, libbladerf), Cint, (Ptr{bladerf}, Ptr{Ptr{bladerf_loopback_modes}}), dev, modes)
end

function bladerf_is_loopback_mode_supported(dev, mode)
    ccall((:bladerf_is_loopback_mode_supported, libbladerf), Bool, (Ptr{bladerf}, bladerf_loopback), dev, mode)
end

function bladerf_set_loopback(dev, lb)
    ccall((:bladerf_set_loopback, libbladerf), Cint, (Ptr{bladerf}, bladerf_loopback), dev, lb)
end

function bladerf_get_loopback(dev, lb)
    ccall((:bladerf_get_loopback, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_loopback}), dev, lb)
end

@cenum bladerf_trigger_role::Int32 begin
    BLADERF_TRIGGER_ROLE_INVALID = -1
    BLADERF_TRIGGER_ROLE_DISABLED = 0
    BLADERF_TRIGGER_ROLE_MASTER = 1
    BLADERF_TRIGGER_ROLE_SLAVE = 2
end

@cenum bladerf_trigger_signal::Int32 begin
    BLADERF_TRIGGER_INVALID = -1
    BLADERF_TRIGGER_J71_4 = 0
    BLADERF_TRIGGER_J51_1 = 1
    BLADERF_TRIGGER_MINI_EXP_1 = 2
    BLADERF_TRIGGER_USER_0 = 128
    BLADERF_TRIGGER_USER_1 = 129
    BLADERF_TRIGGER_USER_2 = 130
    BLADERF_TRIGGER_USER_3 = 131
    BLADERF_TRIGGER_USER_4 = 132
    BLADERF_TRIGGER_USER_5 = 133
    BLADERF_TRIGGER_USER_6 = 134
    BLADERF_TRIGGER_USER_7 = 135
end

struct bladerf_trigger
    channel::bladerf_channel
    role::bladerf_trigger_role
    signal::bladerf_trigger_signal
    options::UInt64
end

function bladerf_trigger_init(dev, ch, signal, trigger)
    ccall((:bladerf_trigger_init, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, bladerf_trigger_signal, Ptr{bladerf_trigger}), dev, ch, signal, trigger)
end

function bladerf_trigger_arm(dev, trigger, arm, resv1, resv2)
    ccall((:bladerf_trigger_arm, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_trigger}, Bool, UInt64, UInt64), dev, trigger, arm, resv1, resv2)
end

function bladerf_trigger_fire(dev, trigger)
    ccall((:bladerf_trigger_fire, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_trigger}), dev, trigger)
end

function bladerf_trigger_state(dev, trigger, is_armed, has_fired, fire_requested, resv1, resv2)
    ccall((:bladerf_trigger_state, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_trigger}, Ptr{Bool}, Ptr{Bool}, Ptr{Bool}, Ptr{UInt64}, Ptr{UInt64}), dev, trigger, is_armed, has_fired, fire_requested, resv1, resv2)
end

@cenum bladerf_rx_mux::Int32 begin
    BLADERF_RX_MUX_INVALID = -1
    BLADERF_RX_MUX_BASEBAND = 0
    BLADERF_RX_MUX_12BIT_COUNTER = 1
    BLADERF_RX_MUX_32BIT_COUNTER = 2
    BLADERF_RX_MUX_DIGITAL_LOOPBACK = 4
end

function bladerf_set_rx_mux(dev, mux)
    ccall((:bladerf_set_rx_mux, libbladerf), Cint, (Ptr{bladerf}, bladerf_rx_mux), dev, mux)
end

function bladerf_get_rx_mux(dev, mode)
    ccall((:bladerf_get_rx_mux, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_rx_mux}), dev, mode)
end

struct bladerf_quick_tune
    data::NTuple{12, UInt8}
end

function Base.getproperty(x::Ptr{bladerf_quick_tune}, f::Symbol)
    f === :freqsel && return Ptr{UInt8}(x + 0)
    f === :vcocap && return Ptr{UInt8}(x + 1)
    f === :nint && return Ptr{UInt16}(x + 2)
    f === :nfrac && return Ptr{UInt32}(x + 4)
    f === :flags && return Ptr{UInt8}(x + 8)
    f === :xb_gpio && return Ptr{UInt8}(x + 9)
    f === :nios_profile && return Ptr{UInt16}(x + 0)
    f === :rffe_profile && return Ptr{UInt8}(x + 2)
    f === :port && return Ptr{UInt8}(x + 3)
    f === :spdt && return Ptr{UInt8}(x + 4)
    return getfield(x, f)
end

function Base.getproperty(x::bladerf_quick_tune, f::Symbol)
    r = Ref{bladerf_quick_tune}(x)
    ptr = Base.unsafe_convert(Ptr{bladerf_quick_tune}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{bladerf_quick_tune}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

function bladerf_schedule_retune(dev, ch, timestamp, frequency, quick_tune)
    ccall((:bladerf_schedule_retune, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, bladerf_timestamp, bladerf_frequency, Ptr{bladerf_quick_tune}), dev, ch, timestamp, frequency, quick_tune)
end

function bladerf_cancel_scheduled_retunes(dev, ch)
    ccall((:bladerf_cancel_scheduled_retunes, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel), dev, ch)
end

function bladerf_get_quick_tune(dev, ch, quick_tune)
    ccall((:bladerf_get_quick_tune, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{bladerf_quick_tune}), dev, ch, quick_tune)
end

const bladerf_correction_value = Int16

@cenum bladerf_correction::UInt32 begin
    BLADERF_CORR_DCOFF_I = 0
    BLADERF_CORR_DCOFF_Q = 1
    BLADERF_CORR_PHASE = 2
    BLADERF_CORR_GAIN = 3
end

function bladerf_set_correction(dev, ch, corr, value)
    ccall((:bladerf_set_correction, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, bladerf_correction, bladerf_correction_value), dev, ch, corr, value)
end

function bladerf_get_correction(dev, ch, corr, value)
    ccall((:bladerf_get_correction, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, bladerf_correction, Ptr{bladerf_correction_value}), dev, ch, corr, value)
end

@cenum bladerf_format::UInt32 begin
    BLADERF_FORMAT_SC16_Q11 = 0
    BLADERF_FORMAT_SC16_Q11_META = 1
    BLADERF_FORMAT_PACKET_META = 2
end

mutable struct bladerf_metadata
    timestamp::bladerf_timestamp
    flags::UInt32
    status::UInt32
    actual_count::Cuint
    reserved::NTuple{32, UInt8}
end

function bladerf_interleave_stream_buffer(layout, format, buffer_size, samples)
    ccall((:bladerf_interleave_stream_buffer, libbladerf), Cint, (bladerf_channel_layout, bladerf_format, Cuint, Ptr{Cvoid}), layout, format, buffer_size, samples)
end

function bladerf_deinterleave_stream_buffer(layout, format, buffer_size, samples)
    ccall((:bladerf_deinterleave_stream_buffer, libbladerf), Cint, (bladerf_channel_layout, bladerf_format, Cuint, Ptr{Cvoid}), layout, format, buffer_size, samples)
end

function bladerf_enable_module(dev, ch, enable)
    ccall((:bladerf_enable_module, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Bool), dev, ch, enable)
end

function bladerf_get_timestamp(dev, dir, timestamp)
    ccall((:bladerf_get_timestamp, libbladerf), Cint, (Ptr{bladerf}, bladerf_direction, Ptr{bladerf_timestamp}), dev, dir, timestamp)
end

function bladerf_sync_config(dev, layout, format, num_buffers, buffer_size, num_transfers, stream_timeout)
    ccall((:bladerf_sync_config, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel_layout, bladerf_format, Cuint, Cuint, Cuint, Cuint), dev, layout, format, num_buffers, buffer_size, num_transfers, stream_timeout)
end

function bladerf_sync_tx(dev, samples, num_samples, metadata, timeout_ms)
    ccall((:bladerf_sync_tx, libbladerf), Cint, (Ptr{bladerf}, Ptr{Cvoid}, Cuint, Ptr{bladerf_metadata}, Cuint), dev, samples, num_samples, metadata, timeout_ms)
end

function bladerf_sync_rx(dev, samples, num_samples, metadata, timeout_ms)
    ccall((:bladerf_sync_rx, libbladerf), Cint, (Ptr{bladerf}, Ptr{Cvoid}, Cuint, Ptr{bladerf_metadata}, Cuint), dev, samples, num_samples, metadata, timeout_ms)
end

mutable struct bladerf_stream end

# typedef void * ( * bladerf_stream_cb ) ( struct bladerf * dev , struct bladerf_stream * stream , struct bladerf_metadata * meta , void * samples , size_t num_samples , void * user_data )
const bladerf_stream_cb = Ptr{Cvoid}

function bladerf_init_stream(stream, dev, callback, buffers, num_buffers, format, samples_per_buffer, num_transfers, user_data)
    ccall((:bladerf_init_stream, libbladerf), Cint, (Ptr{Ptr{bladerf_stream}}, Ptr{bladerf}, bladerf_stream_cb, Ptr{Ptr{Ptr{Cvoid}}}, Csize_t, bladerf_format, Csize_t, Csize_t, Ptr{Cvoid}), stream, dev, callback, buffers, num_buffers, format, samples_per_buffer, num_transfers, user_data)
end

function bladerf_stream(stream, layout)
    ccall((:bladerf_stream, libbladerf), Cint, (Ptr{bladerf_stream}, bladerf_channel_layout), stream, layout)
end

function bladerf_submit_stream_buffer(stream, buffer, timeout_ms)
    ccall((:bladerf_submit_stream_buffer, libbladerf), Cint, (Ptr{bladerf_stream}, Ptr{Cvoid}, Cuint), stream, buffer, timeout_ms)
end

function bladerf_submit_stream_buffer_nb(stream, buffer)
    ccall((:bladerf_submit_stream_buffer_nb, libbladerf), Cint, (Ptr{bladerf_stream}, Ptr{Cvoid}), stream, buffer)
end

function bladerf_deinit_stream(stream)
    ccall((:bladerf_deinit_stream, libbladerf), Cvoid, (Ptr{bladerf_stream},), stream)
end

function bladerf_set_stream_timeout(dev, dir, timeout)
    ccall((:bladerf_set_stream_timeout, libbladerf), Cint, (Ptr{bladerf}, bladerf_direction, Cuint), dev, dir, timeout)
end

function bladerf_get_stream_timeout(dev, dir, timeout)
    ccall((:bladerf_get_stream_timeout, libbladerf), Cint, (Ptr{bladerf}, bladerf_direction, Ptr{Cuint}), dev, dir, timeout)
end

function bladerf_flash_firmware(dev, firmware)
    ccall((:bladerf_flash_firmware, libbladerf), Cint, (Ptr{bladerf}, Ptr{Cchar}), dev, firmware)
end

function bladerf_load_fpga(dev, fpga)
    ccall((:bladerf_load_fpga, libbladerf), Cint, (Ptr{bladerf}, Ptr{Cchar}), dev, fpga)
end

function bladerf_flash_fpga(dev, fpga_image)
    ccall((:bladerf_flash_fpga, libbladerf), Cint, (Ptr{bladerf}, Ptr{Cchar}), dev, fpga_image)
end

function bladerf_erase_stored_fpga(dev)
    ccall((:bladerf_erase_stored_fpga, libbladerf), Cint, (Ptr{bladerf},), dev)
end

function bladerf_device_reset(dev)
    ccall((:bladerf_device_reset, libbladerf), Cint, (Ptr{bladerf},), dev)
end

function bladerf_get_fw_log(dev, filename)
    ccall((:bladerf_get_fw_log, libbladerf), Cint, (Ptr{bladerf}, Ptr{Cchar}), dev, filename)
end

function bladerf_jump_to_bootloader(dev)
    ccall((:bladerf_jump_to_bootloader, libbladerf), Cint, (Ptr{bladerf},), dev)
end

function bladerf_get_bootloader_list(list)
    ccall((:bladerf_get_bootloader_list, libbladerf), Cint, (Ptr{Ptr{bladerf_devinfo}},), list)
end

function bladerf_load_fw_from_bootloader(device_identifier, backend, bus, addr, file)
    ccall((:bladerf_load_fw_from_bootloader, libbladerf), Cint, (Ptr{Cchar}, bladerf_backend, UInt8, UInt8, Ptr{Cchar}), device_identifier, backend, bus, addr, file)
end

@cenum bladerf_image_type::Int32 begin
    BLADERF_IMAGE_TYPE_INVALID = -1
    BLADERF_IMAGE_TYPE_RAW = 0
    BLADERF_IMAGE_TYPE_FIRMWARE = 1
    BLADERF_IMAGE_TYPE_FPGA_40KLE = 2
    BLADERF_IMAGE_TYPE_FPGA_115KLE = 3
    BLADERF_IMAGE_TYPE_FPGA_A4 = 4
    BLADERF_IMAGE_TYPE_FPGA_A9 = 5
    BLADERF_IMAGE_TYPE_CALIBRATION = 6
    BLADERF_IMAGE_TYPE_RX_DC_CAL = 7
    BLADERF_IMAGE_TYPE_TX_DC_CAL = 8
    BLADERF_IMAGE_TYPE_RX_IQ_CAL = 9
    BLADERF_IMAGE_TYPE_TX_IQ_CAL = 10
    BLADERF_IMAGE_TYPE_FPGA_A5 = 11
end

struct bladerf_image
    magic::NTuple{8, Cchar}
    checksum::NTuple{32, UInt8}
    version::bladerf_version
    timestamp::UInt64
    serial::NTuple{34, Cchar}
    reserved::NTuple{128, Cchar}
    type::bladerf_image_type
    address::UInt32
    length::UInt32
    data::Ptr{UInt8}
end

function bladerf_alloc_image(dev, type, address, length)
    ccall((:bladerf_alloc_image, libbladerf), Ptr{bladerf_image}, (Ptr{bladerf}, bladerf_image_type, UInt32, UInt32), dev, type, address, length)
end

function bladerf_alloc_cal_image(dev, fpga_size, vctcxo_trim)
    ccall((:bladerf_alloc_cal_image, libbladerf), Ptr{bladerf_image}, (Ptr{bladerf}, bladerf_fpga_size, UInt16), dev, fpga_size, vctcxo_trim)
end

function bladerf_free_image(image)
    ccall((:bladerf_free_image, libbladerf), Cvoid, (Ptr{bladerf_image},), image)
end

function bladerf_image_write(dev, image, file)
    ccall((:bladerf_image_write, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_image}, Ptr{Cchar}), dev, image, file)
end

function bladerf_image_read(image, file)
    ccall((:bladerf_image_read, libbladerf), Cint, (Ptr{bladerf_image}, Ptr{Cchar}), image, file)
end

@cenum bladerf_vctcxo_tamer_mode::Int32 begin
    BLADERF_VCTCXO_TAMER_INVALID = -1
    BLADERF_VCTCXO_TAMER_DISABLED = 0
    BLADERF_VCTCXO_TAMER_1_PPS = 1
    BLADERF_VCTCXO_TAMER_10_MHZ = 2
end

function bladerf_set_vctcxo_tamer_mode(dev, mode)
    ccall((:bladerf_set_vctcxo_tamer_mode, libbladerf), Cint, (Ptr{bladerf}, bladerf_vctcxo_tamer_mode), dev, mode)
end

function bladerf_get_vctcxo_tamer_mode(dev, mode)
    ccall((:bladerf_get_vctcxo_tamer_mode, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_vctcxo_tamer_mode}), dev, mode)
end

function bladerf_get_vctcxo_trim(dev, trim)
    ccall((:bladerf_get_vctcxo_trim, libbladerf), Cint, (Ptr{bladerf}, Ptr{UInt16}), dev, trim)
end

function bladerf_trim_dac_write(dev, val)
    ccall((:bladerf_trim_dac_write, libbladerf), Cint, (Ptr{bladerf}, UInt16), dev, val)
end

function bladerf_trim_dac_read(dev, val)
    ccall((:bladerf_trim_dac_read, libbladerf), Cint, (Ptr{bladerf}, Ptr{UInt16}), dev, val)
end

@cenum bladerf_tuning_mode::Int32 begin
    BLADERF_TUNING_MODE_INVALID = -1
    BLADERF_TUNING_MODE_HOST = 0
    BLADERF_TUNING_MODE_FPGA = 1
end

function bladerf_set_tuning_mode(dev, mode)
    ccall((:bladerf_set_tuning_mode, libbladerf), Cint, (Ptr{bladerf}, bladerf_tuning_mode), dev, mode)
end

function bladerf_get_tuning_mode(dev, mode)
    ccall((:bladerf_get_tuning_mode, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_tuning_mode}), dev, mode)
end

function bladerf_read_trigger(dev, ch, signal, val)
    ccall((:bladerf_read_trigger, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, bladerf_trigger_signal, Ptr{UInt8}), dev, ch, signal, val)
end

function bladerf_write_trigger(dev, ch, signal, val)
    ccall((:bladerf_write_trigger, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, bladerf_trigger_signal, UInt8), dev, ch, signal, val)
end

function bladerf_wishbone_master_read(dev, addr, data)
    ccall((:bladerf_wishbone_master_read, libbladerf), Cint, (Ptr{bladerf}, UInt32, Ptr{UInt32}), dev, addr, data)
end

function bladerf_wishbone_master_write(dev, addr, val)
    ccall((:bladerf_wishbone_master_write, libbladerf), Cint, (Ptr{bladerf}, UInt32, UInt32), dev, addr, val)
end

function bladerf_config_gpio_read(dev, val)
    ccall((:bladerf_config_gpio_read, libbladerf), Cint, (Ptr{bladerf}, Ptr{UInt32}), dev, val)
end

function bladerf_config_gpio_write(dev, val)
    ccall((:bladerf_config_gpio_write, libbladerf), Cint, (Ptr{bladerf}, UInt32), dev, val)
end

function bladerf_erase_flash(dev, erase_block, count)
    ccall((:bladerf_erase_flash, libbladerf), Cint, (Ptr{bladerf}, UInt32, UInt32), dev, erase_block, count)
end

function bladerf_erase_flash_bytes(dev, address, length)
    ccall((:bladerf_erase_flash_bytes, libbladerf), Cint, (Ptr{bladerf}, UInt32, UInt32), dev, address, length)
end

function bladerf_read_flash(dev, buf, page, count)
    ccall((:bladerf_read_flash, libbladerf), Cint, (Ptr{bladerf}, Ptr{UInt8}, UInt32, UInt32), dev, buf, page, count)
end

function bladerf_read_flash_bytes(dev, buf, address, bytes)
    ccall((:bladerf_read_flash_bytes, libbladerf), Cint, (Ptr{bladerf}, Ptr{UInt8}, UInt32, UInt32), dev, buf, address, bytes)
end

function bladerf_write_flash(dev, buf, page, count)
    ccall((:bladerf_write_flash, libbladerf), Cint, (Ptr{bladerf}, Ptr{UInt8}, UInt32, UInt32), dev, buf, page, count)
end

function bladerf_write_flash_bytes(dev, buf, address, length)
    ccall((:bladerf_write_flash_bytes, libbladerf), Cint, (Ptr{bladerf}, Ptr{UInt8}, UInt32, UInt32), dev, buf, address, length)
end

function bladerf_lock_otp(dev)
    ccall((:bladerf_lock_otp, libbladerf), Cint, (Ptr{bladerf},), dev)
end

function bladerf_read_otp(dev, buf)
    ccall((:bladerf_read_otp, libbladerf), Cint, (Ptr{bladerf}, Ptr{UInt8}), dev, buf)
end

function bladerf_write_otp(dev, buf)
    ccall((:bladerf_write_otp, libbladerf), Cint, (Ptr{bladerf}, Ptr{UInt8}), dev, buf)
end

function bladerf_set_rf_port(dev, ch, port)
    ccall((:bladerf_set_rf_port, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{Cchar}), dev, ch, port)
end

function bladerf_get_rf_port(dev, ch, port)
    ccall((:bladerf_get_rf_port, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{Ptr{Cchar}}), dev, ch, port)
end

function bladerf_get_rf_ports(dev, ch, ports, count)
    ccall((:bladerf_get_rf_ports, libbladerf), Cint, (Ptr{bladerf}, bladerf_channel, Ptr{Ptr{Cchar}}, Cuint), dev, ch, ports, count)
end

@cenum bladerf_xb::UInt32 begin
    BLADERF_XB_NONE = 0
    BLADERF_XB_100 = 1
    BLADERF_XB_200 = 2
    BLADERF_XB_300 = 3
end

function bladerf_expansion_attach(dev, xb)
    ccall((:bladerf_expansion_attach, libbladerf), Cint, (Ptr{bladerf}, bladerf_xb), dev, xb)
end

function bladerf_expansion_get_attached(dev, xb)
    ccall((:bladerf_expansion_get_attached, libbladerf), Cint, (Ptr{bladerf}, Ptr{bladerf_xb}), dev, xb)
end

@cenum bladerf_log_level::UInt32 begin
    BLADERF_LOG_LEVEL_VERBOSE = 0
    BLADERF_LOG_LEVEL_DEBUG = 1
    BLADERF_LOG_LEVEL_INFO = 2
    BLADERF_LOG_LEVEL_WARNING = 3
    BLADERF_LOG_LEVEL_ERROR = 4
    BLADERF_LOG_LEVEL_CRITICAL = 5
    BLADERF_LOG_LEVEL_SILENT = 6
end

function bladerf_log_set_verbosity(level)
    ccall((:bladerf_log_set_verbosity, libbladerf), Cvoid, (bladerf_log_level,), level)
end

function bladerf_version(version)
    ccall((:bladerf_version, libbladerf), Cvoid, (Ptr{bladerf_version},), version)
end

function bladerf_strerror(error)
    ccall((:bladerf_strerror, libbladerf), Ptr{Cchar}, (Cint,), error)
end

const BLADERF_SAMPLERATE_MIN = Cuint(80000)

const BLADERF_SAMPLERATE_REC_MAX = Cuint(40000000)

const BLADERF_BANDWIDTH_MIN = Cuint(1500000)

const BLADERF_BANDWIDTH_MAX = Cuint(28000000)

const BLADERF_FREQUENCY_MIN_XB200 = Cuint(0)

const BLADERF_FREQUENCY_MIN = Cuint(237500000)

const BLADERF_FREQUENCY_MAX = Cuint(3800000000)

const BLADERF_FLASH_ADDR_FIRMWARE = 0x00000000

const BLADERF_FLASH_BYTE_LEN_FIRMWARE = 0x00030000

const BLADERF_FLASH_ADDR_CAL = 0x00030000

const BLADERF_FLASH_BYTE_LEN_CAL = 0x0100

const BLADERF_FLASH_ADDR_FPGA = 0x00040000

const BLADERF_RXVGA1_GAIN_MIN = 5

const BLADERF_RXVGA1_GAIN_MAX = 30

const BLADERF_RXVGA2_GAIN_MIN = 0

const BLADERF_RXVGA2_GAIN_MAX = 30

const BLADERF_TXVGA1_GAIN_MIN = -35

const BLADERF_TXVGA1_GAIN_MAX = -4

const BLADERF_TXVGA2_GAIN_MIN = 0

const BLADERF_TXVGA2_GAIN_MAX = 25

const BLADERF_LNA_GAIN_MID_DB = 3

const BLADERF_LNA_GAIN_MAX_DB = 6

const BLADERF_SMB_FREQUENCY_MAX = Cuint(200000000)

const BLADERF_SMB_FREQUENCY_MIN = (Cuint(38400000) * Cuint(66)) ÷ (32 * 567)


 
const BLADERF_XB_GPIO_01 = BLADERF_XB_GPIO(1)

const BLADERF_XB_GPIO_02 = BLADERF_XB_GPIO(2)

const BLADERF_XB_GPIO_03 = BLADERF_XB_GPIO(3)

const BLADERF_XB_GPIO_04 = BLADERF_XB_GPIO(4)

const BLADERF_XB_GPIO_05 = BLADERF_XB_GPIO(5)

const BLADERF_XB_GPIO_06 = BLADERF_XB_GPIO(6)

const BLADERF_XB_GPIO_07 = BLADERF_XB_GPIO(7)

const BLADERF_XB_GPIO_08 = BLADERF_XB_GPIO(8)

const BLADERF_XB_GPIO_09 = BLADERF_XB_GPIO(9)

const BLADERF_XB_GPIO_10 = BLADERF_XB_GPIO(10)

const BLADERF_XB_GPIO_11 = BLADERF_XB_GPIO(11)

const BLADERF_XB_GPIO_12 = BLADERF_XB_GPIO(12)

const BLADERF_XB_GPIO_13 = BLADERF_XB_GPIO(13)

const BLADERF_XB_GPIO_14 = BLADERF_XB_GPIO(14)

const BLADERF_XB_GPIO_15 = BLADERF_XB_GPIO(15)

const BLADERF_XB_GPIO_16 = BLADERF_XB_GPIO(16)

const BLADERF_XB_GPIO_17 = BLADERF_XB_GPIO(17)

const BLADERF_XB_GPIO_18 = BLADERF_XB_GPIO(18)

const BLADERF_XB_GPIO_19 = BLADERF_XB_GPIO(19)

const BLADERF_XB_GPIO_20 = BLADERF_XB_GPIO(20)

const BLADERF_XB_GPIO_21 = BLADERF_XB_GPIO(21)

const BLADERF_XB_GPIO_22 = BLADERF_XB_GPIO(22)

const BLADERF_XB_GPIO_23 = BLADERF_XB_GPIO(23)

const BLADERF_XB_GPIO_24 = BLADERF_XB_GPIO(24)

const BLADERF_XB_GPIO_25 = BLADERF_XB_GPIO(25)

const BLADERF_XB_GPIO_26 = BLADERF_XB_GPIO(26)

const BLADERF_XB_GPIO_27 = BLADERF_XB_GPIO(27)

const BLADERF_XB_GPIO_28 = BLADERF_XB_GPIO(28)

const BLADERF_XB_GPIO_29 = BLADERF_XB_GPIO(29)

const BLADERF_XB_GPIO_30 = BLADERF_XB_GPIO(30)

const BLADERF_XB_GPIO_31 = BLADERF_XB_GPIO(31)

const BLADERF_XB_GPIO_32 = BLADERF_XB_GPIO(32)

const BLADERF_XB200_PIN_J7_1 = BLADERF_XB_GPIO_10

const BLADERF_XB200_PIN_J7_2 = BLADERF_XB_GPIO_11

const BLADERF_XB200_PIN_J7_5 = BLADERF_XB_GPIO_08

const BLADERF_XB200_PIN_J7_6 = BLADERF_XB_GPIO_09

const BLADERF_XB200_PIN_J13_1 = BLADERF_XB_GPIO_17

const BLADERF_XB200_PIN_J13_2 = BLADERF_XB_GPIO_18

const BLADERF_XB200_PIN_J16_1 = BLADERF_XB_GPIO_31

const BLADERF_XB200_PIN_J16_2 = BLADERF_XB_GPIO_32

const BLADERF_XB200_PIN_J16_3 = BLADERF_XB_GPIO_19

const BLADERF_XB200_PIN_J16_4 = BLADERF_XB_GPIO_20

const BLADERF_XB200_PIN_J16_5 = BLADERF_XB_GPIO_21

const BLADERF_XB200_PIN_J16_6 = BLADERF_XB_GPIO_24

const BLADERF_XB100_PIN_J2_3 = BLADERF_XB_GPIO_07

const BLADERF_XB100_PIN_J2_4 = BLADERF_XB_GPIO_08

const BLADERF_XB100_PIN_J3_3 = BLADERF_XB_GPIO_09

const BLADERF_XB100_PIN_J3_4 = BLADERF_XB_GPIO_10

const BLADERF_XB100_PIN_J4_3 = BLADERF_XB_GPIO_11

const BLADERF_XB100_PIN_J4_4 = BLADERF_XB_GPIO_12

const BLADERF_XB100_PIN_J5_3 = BLADERF_XB_GPIO_13

const BLADERF_XB100_PIN_J5_4 = BLADERF_XB_GPIO_14

const BLADERF_XB100_PIN_J11_2 = BLADERF_XB_GPIO_05

const BLADERF_XB100_PIN_J11_3 = BLADERF_XB_GPIO_04

const BLADERF_XB100_PIN_J11_4 = BLADERF_XB_GPIO_03

const BLADERF_XB100_PIN_J11_5 = BLADERF_XB_GPIO_06

const BLADERF_XB100_PIN_J12_2 = BLADERF_XB_GPIO_01

const BLADERF_XB100_PIN_J12_5 = BLADERF_XB_GPIO_02

const BLADERF_XB100_LED_D1 = BLADERF_XB_GPIO_24

const BLADERF_XB100_LED_D2 = BLADERF_XB_GPIO_32

const BLADERF_XB100_LED_D3 = BLADERF_XB_GPIO_30

const BLADERF_XB100_LED_D4 = BLADERF_XB_GPIO_28

const BLADERF_XB100_LED_D5 = BLADERF_XB_GPIO_23

const BLADERF_XB100_LED_D6 = BLADERF_XB_GPIO_25

const BLADERF_XB100_LED_D7 = BLADERF_XB_GPIO_31

const BLADERF_XB100_LED_D8 = BLADERF_XB_GPIO_29

const BLADERF_XB100_TLED_RED = BLADERF_XB_GPIO_22

const BLADERF_XB100_TLED_GREEN = BLADERF_XB_GPIO_21

const BLADERF_XB100_TLED_BLUE = BLADERF_XB_GPIO_20

const BLADERF_XB100_DIP_SW1 = BLADERF_XB_GPIO_27

const BLADERF_XB100_DIP_SW2 = BLADERF_XB_GPIO_26

const BLADERF_XB100_DIP_SW3 = BLADERF_XB_GPIO_16

const BLADERF_XB100_DIP_SW4 = BLADERF_XB_GPIO_15

const BLADERF_XB100_BTN_J6 = BLADERF_XB_GPIO_19

const BLADERF_XB100_BTN_J7 = BLADERF_XB_GPIO_18

const BLADERF_XB100_BTN_J8 = BLADERF_XB_GPIO_17

const BLADERF_GPIO_LMS_RX_ENABLE = 1 << 1

const BLADERF_GPIO_LMS_TX_ENABLE = 1 << 2

const BLADERF_GPIO_TX_LB_ENABLE = 2 << 3

const BLADERF_GPIO_TX_HB_ENABLE = 1 << 3

const BLADERF_GPIO_COUNTER_ENABLE = 1 << 9

const BLADERF_GPIO_RX_MUX_SHIFT = 8

const BLADERF_GPIO_RX_MUX_MASK = 0x07 << BLADERF_GPIO_RX_MUX_SHIFT

const BLADERF_GPIO_RX_LB_ENABLE = 2 << 5

const BLADERF_GPIO_RX_HB_ENABLE = 1 << 5

const BLADERF_GPIO_FEATURE_SMALL_DMA_XFER = 1 << 7

const BLADERF_GPIO_PACKET = 1 << 19

const BLADERF_GPIO_AGC_ENABLE = 1 << 18

const BLADERF_GPIO_TIMESTAMP = 1 << 16

const BLADERF_GPIO_TIMESTAMP_DIV2 = 1 << 17

const BLADERF_GPIO_PACKET_CORE_PRESENT = 1 << 28

const BLADERF_RFIC_RXFIR_DEFAULT = BLADERF_RFIC_RXFIR_DEC1

const BLADERF_RFIC_TXFIR_DEFAULT = BLADERF_RFIC_TXFIR_BYPASS

const LIBBLADERF_API_VERSION = 0x02040100

# Skipping MacroDefinition: API_EXPORT __attribute__ ( ( visibility ( "default" ) ) )

const BLADERF_DESCRIPTION_LENGTH = 33

const BLADERF_SERIAL_LENGTH = 33

const BLADERF_CHANNEL_INVALID = bladerf_channel(-1)

const BLADERF_DIRECTION_MASK = 0x01

const BLADERF_MODULE_INVALID = BLADERF_CHANNEL_INVALID

const BLADERF_MODULE_RX = BLADERF_CHANNEL_RX(0)

const BLADERF_MODULE_TX = BLADERF_CHANNEL_TX(0)

const BLADERF_GAIN_AUTOMATIC = BLADERF_GAIN_DEFAULT

const BLADERF_GAIN_MANUAL = BLADERF_GAIN_MGC

#const BLADERF_PRIuFREQ = PRIu64

#const BLADERF_PRIxFREQ = PRIx64

#const BLADERF_SCNuFREQ = SCNu64

#const BLADERF_SCNxFREQ = SCNx64

const BLADERF_RX_MUX_BASEBAND_LMS = BLADERF_RX_MUX_BASEBAND

const BLADERF_RETUNE_NOW = bladerf_timestamp(0)

const BLADERF_CORR_LMS_DCOFF_I = BLADERF_CORR_DCOFF_I

const BLADERF_CORR_LMS_DCOFF_Q = BLADERF_CORR_DCOFF_Q

const BLADERF_CORR_FPGA_PHASE = BLADERF_CORR_PHASE

const BLADERF_CORR_FPGA_GAIN = BLADERF_CORR_GAIN

#const BLADERF_PRIuTS = PRIu64

#const BLADERF_PRIxTS = PRIx64

#const BLADERF_SCNuTS = SCNu64

#const BLADERF_SCNxTS = SCNx64

const BLADERF_META_STATUS_OVERRUN = 1 << 0

const BLADERF_META_STATUS_UNDERRUN = 1 << 1

const BLADERF_META_FLAG_TX_BURST_START = 1 << 0

const BLADERF_META_FLAG_TX_BURST_END = 1 << 1

const BLADERF_META_FLAG_TX_NOW = 1 << 2

const BLADERF_META_FLAG_TX_UPDATE_TIMESTAMP = 1 << 3

const BLADERF_META_FLAG_RX_NOW = 1 << 31

const BLADERF_META_FLAG_RX_HW_UNDERFLOW = 1 << 0

const BLADERF_META_FLAG_RX_HW_MINIEXP1 = 1 << 16

const BLADERF_META_FLAG_RX_HW_MINIEXP2 = 1 << 17

const BLADERF_STREAM_SHUTDOWN =nothing 

# Skipping MacroDefinition: BLADERF_STREAM_NO_DATA ( ( void * ) ( - 1 ) )

const BLADERF_IMAGE_MAGIC_LEN = 7

const BLADERF_IMAGE_CHECKSUM_LEN = 32

const BLADERF_IMAGE_RESERVED_LEN = 128

const BLADERF_TRIGGER_REG_ARM = UInt8(1 << 0)

const BLADERF_TRIGGER_REG_FIRE = UInt8(1 << 1)

const BLADERF_TRIGGER_REG_MASTER = UInt8(1 << 2)

const BLADERF_TRIGGER_REG_LINE = UInt8(1 << 3)

const BLADERF_ERR_UNEXPECTED = -1

const BLADERF_ERR_RANGE = -2

const BLADERF_ERR_INVAL = -3

const BLADERF_ERR_MEM = -4

const BLADERF_ERR_IO = -5

const BLADERF_ERR_TIMEOUT = -6

const BLADERF_ERR_NODEV = -7

const BLADERF_ERR_UNSUPPORTED = -8

const BLADERF_ERR_MISALIGNED = -9

const BLADERF_ERR_CHECKSUM = -10

const BLADERF_ERR_NO_FILE = -11

const BLADERF_ERR_UPDATE_FPGA = -12

const BLADERF_ERR_UPDATE_FW = -13

const BLADERF_ERR_TIME_PAST = -14

const BLADERF_ERR_QUEUE_FULL = -15

const BLADERF_ERR_FPGA_OP = -16

const BLADERF_ERR_PERMISSION = -17

const BLADERF_ERR_WOULD_BLOCK = -18

const BLADERF_ERR_NOT_INIT = -19

# exports
const PREFIXES = ["bladerf_","BLADERF_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end
export bladerf

end # module
