-- local log = require "log"
local utils = require "st.utils"

local zcl_clusters = require "st.zigbee.zcl.clusters"
local capabilities = require "st.capabilities"

local signal = require "signal-metrics"

local MOES_TEMP_HUMUDITY_SENSOR_FINGERPRINTS = {
  { mfr = "_TZ3000_ywagc4rj", model = "TS0201" },
}

local function can_handle_moes_sensor(opts, driver, device)
  for _, fingerprint in ipairs(MOES_TEMP_HUMUDITY_SENSOR_FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      return true
    end
  end
  return false
end

function moes_humidity_attr_handler(driver, device, value, zb_rx)
  if (value.value ~= 0xFFFF) then -- 0xFFFF means the measured value was invalid
    device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value,
      capabilities.relativeHumidityMeasurement.humidity(utils.round(value.value / 10.0)))
  end
end

local moes_sensor = {
  NAME = "MOES Temperature Humidity Sensor",
  zigbee_handlers = {
    attr = {
      [zcl_clusters.RelativeHumidity.ID] = {
        [zcl_clusters.RelativeHumidity.attributes.MeasuredValue.ID] = {moes_humidity_attr_handler, signal.metrics}
      }
    }
  },
  can_handle = can_handle_moes_sensor
}

return moes_sensor
