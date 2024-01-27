--local log = require "log"
--local utils = require "st.utils"

local capabilities = require "st.capabilities"

local PREV_REPORTED_TIME = "reportedTimeSignal"
local MININUM_REPORT_INTERNAL = 3600

local signal = {}

function signal.metrics(driver, device, value, zb_rx)
    signal.metrics_cluster(driver, device, zb_rx)
end

function signal.metrics_cluster(driver, device, zb_rx)
    -- log.debug("RSSI: " .. zb_rx.rssi.value .. " LQI: " .. zb_rx.lqi.value)
    -- emit signal metrics
    local current_time = os.time()
    local prev_reported_time = device:get_field(PREV_REPORTED_TIME) or 0
    local prev_reported_value =
        device.state_cache.main and device.state_cache.main.signalStrength and
        device.state_cache.main.signalStrength.rssi.value or 0
    if current_time - prev_reported_time > MININUM_REPORT_INTERNAL or
        math.abs(prev_reported_value - zb_rx.rssi.value) >= math.abs(prev_reported_value * 0.05) then
        local mt = { visibility = { displayed = false } }
        device:emit_event(capabilities.signalStrength.rssi({ value = zb_rx.rssi.value }, mt))
        device:emit_event(capabilities.signalStrength.lqi({ value = zb_rx.lqi.value }, mt))
        device:set_field(PREV_REPORTED_TIME, current_time)
    end
end

return signal
