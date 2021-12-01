# All bindings of RTLSDR exported by Clang 
module LibRtlsdr
# --- Library call 
using librtlsdr_jll
# --- Dependencies 
using CEnum

# ----------------------------------------------------
# --- Enumeration 
# ---------------------------------------------------- 
@cenum rtlsdr_tuner::UInt32 begin
    RTLSDR_TUNER_UNKNOWN = 0
    RTLSDR_TUNER_E4000 = 1
    RTLSDR_TUNER_FC0012 = 2
    RTLSDR_TUNER_FC0013 = 3
    RTLSDR_TUNER_FC2580 = 4
    RTLSDR_TUNER_R820T = 5
    RTLSDR_TUNER_R828D = 6
end

# ----------------------------------------------------
# --- Runtime structures 
# ---------------------------------------------------- 
mutable struct rtlsdr_dev end
const rtlsdr_dev_t = rtlsdr_dev


# typedef void ( * rtlsdr_read_async_cb_t ) ( unsigned char * buf , uint32_t len , void * ctx )
const rtlsdr_read_async_cb_t = Ptr{Cvoid}

# ----------------------------------------------------
# --- Functions 
# ---------------------------------------------------- 
function rtlsdr_get_device_count()
    ccall((:rtlsdr_get_device_count, librtlsdr), UInt32, ())
end

function rtlsdr_get_device_name(index)
    ccall((:rtlsdr_get_device_name, librtlsdr), Ptr{Cchar}, (UInt32,), index)
end

function rtlsdr_get_device_usb_strings(index, manufact, product, serial)
    ccall((:rtlsdr_get_device_usb_strings, librtlsdr), Cint, (UInt32, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), index, manufact, product, serial)
end

function rtlsdr_get_index_by_serial(serial)
    ccall((:rtlsdr_get_index_by_serial, librtlsdr), Cint, (Ptr{Cchar},), serial)
end

function rtlsdr_open(dev, index)
    ccall((:rtlsdr_open, librtlsdr), Cint, (Ptr{Ptr{rtlsdr_dev_t}}, UInt32), dev, index)
end

function rtlsdr_close(dev)
    ccall((:rtlsdr_close, librtlsdr), Cint, (Ptr{rtlsdr_dev_t},), dev)
end

function rtlsdr_set_xtal_freq(dev, rtl_freq, tuner_freq)
    ccall((:rtlsdr_set_xtal_freq, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, UInt32, UInt32), dev, rtl_freq, tuner_freq)
end

function rtlsdr_get_xtal_freq(dev, rtl_freq, tuner_freq)
    ccall((:rtlsdr_get_xtal_freq, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Ptr{UInt32}, Ptr{UInt32}), dev, rtl_freq, tuner_freq)
end

function rtlsdr_get_usb_strings(dev, manufact, product, serial)
    ccall((:rtlsdr_get_usb_strings, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), dev, manufact, product, serial)
end

function rtlsdr_write_eeprom(dev, data, offset, len)
    ccall((:rtlsdr_write_eeprom, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Ptr{UInt8}, UInt8, UInt16), dev, data, offset, len)
end

function rtlsdr_read_eeprom(dev, data, offset, len)
    ccall((:rtlsdr_read_eeprom, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Ptr{UInt8}, UInt8, UInt16), dev, data, offset, len)
end

function rtlsdr_set_center_freq(dev, freq)
    ccall((:rtlsdr_set_center_freq, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, UInt32), dev, freq)
end

function rtlsdr_get_center_freq(dev)
    ccall((:rtlsdr_get_center_freq, librtlsdr), UInt32, (Ptr{rtlsdr_dev_t},), dev)
end

function rtlsdr_set_freq_correction(dev, ppm)
    ccall((:rtlsdr_set_freq_correction, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Cint), dev, ppm)
end

function rtlsdr_get_freq_correction(dev)
    ccall((:rtlsdr_get_freq_correction, librtlsdr), Cint, (Ptr{rtlsdr_dev_t},), dev)
end

function rtlsdr_get_tuner_type(dev)
    ccall((:rtlsdr_get_tuner_type, librtlsdr), rtlsdr_tuner, (Ptr{rtlsdr_dev_t},), dev)
end

function rtlsdr_get_tuner_gains(dev, gains)
    ccall((:rtlsdr_get_tuner_gains, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Ptr{Cint}), dev, gains)
end

function rtlsdr_set_tuner_gain(dev, gain)
    ccall((:rtlsdr_set_tuner_gain, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Cint), dev, gain)
end

function rtlsdr_set_tuner_bandwidth(dev, bw)
    ccall((:rtlsdr_set_tuner_bandwidth, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, UInt32), dev, bw)
end

function rtlsdr_get_tuner_gain(dev)
    ccall((:rtlsdr_get_tuner_gain, librtlsdr), Cint, (Ptr{rtlsdr_dev_t},), dev)
end

function rtlsdr_set_tuner_if_gain(dev, stage, gain)
    ccall((:rtlsdr_set_tuner_if_gain, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Cint, Cint), dev, stage, gain)
end

function rtlsdr_set_tuner_gain_mode(dev, manual)
    ccall((:rtlsdr_set_tuner_gain_mode, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Cint), dev, manual)
end

function rtlsdr_set_sample_rate(dev, rate)
    ccall((:rtlsdr_set_sample_rate, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, UInt32), dev, rate)
end

function rtlsdr_get_sample_rate(dev)
    ccall((:rtlsdr_get_sample_rate, librtlsdr), UInt32, (Ptr{rtlsdr_dev_t},), dev)
end

function rtlsdr_set_testmode(dev, on)
    ccall((:rtlsdr_set_testmode, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Cint), dev, on)
end

function rtlsdr_set_agc_mode(dev, on)
    ccall((:rtlsdr_set_agc_mode, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Cint), dev, on)
end

function rtlsdr_set_direct_sampling(dev, on)
    ccall((:rtlsdr_set_direct_sampling, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Cint), dev, on)
end

function rtlsdr_get_direct_sampling(dev)
    ccall((:rtlsdr_get_direct_sampling, librtlsdr), Cint, (Ptr{rtlsdr_dev_t},), dev)
end

function rtlsdr_set_offset_tuning(dev, on)
    ccall((:rtlsdr_set_offset_tuning, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Cint), dev, on)
end

function rtlsdr_get_offset_tuning(dev)
    ccall((:rtlsdr_get_offset_tuning, librtlsdr), Cint, (Ptr{rtlsdr_dev_t},), dev)
end

function rtlsdr_reset_buffer(dev)
    ccall((:rtlsdr_reset_buffer, librtlsdr), Cint, (Ptr{rtlsdr_dev_t},), dev)
end

function rtlsdr_read_sync(dev, buf, len, n_read)
    ccall((:rtlsdr_read_sync, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Ptr{Cvoid}, Cint, Ptr{Cint}), dev, buf, len, n_read)
end

function rtlsdr_wait_async(dev, cb, ctx)
    ccall((:rtlsdr_wait_async, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, rtlsdr_read_async_cb_t, Ptr{Cvoid}), dev, cb, ctx)
end

function rtlsdr_read_async(dev, cb, ctx, buf_num, buf_len)
    ccall((:rtlsdr_read_async, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, rtlsdr_read_async_cb_t, Ptr{Cvoid}, UInt32, UInt32), dev, cb, ctx, buf_num, buf_len)
end

function rtlsdr_cancel_async(dev)
    ccall((:rtlsdr_cancel_async, librtlsdr), Cint, (Ptr{rtlsdr_dev_t},), dev)
end

function rtlsdr_set_bias_tee(dev, on)
    ccall((:rtlsdr_set_bias_tee, librtlsdr), Cint, (Ptr{rtlsdr_dev_t}, Cint), dev, on)
end


# exports
const PREFIXES = ["rtlsdr_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end



end
