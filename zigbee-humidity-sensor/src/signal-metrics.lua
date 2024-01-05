--local log = require "log"
--local utils = require "st.utils"

local capabilities = require "st.capabilities"

local signal = {}

function signal.metrics(driver, device, value, zb_rx)
  -- emit signal metrics
  local mt = { visibility = { displayed = false } }
  device:emit_event(capabilities.signalStrength.rssi({ value = zb_rx.rssi.value }, mt))
  device:emit_event(capabilities.signalStrength.lqi({ value = zb_rx.lqi.value }, mt))
end

return signal
