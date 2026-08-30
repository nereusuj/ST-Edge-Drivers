-- local log = require "log"
local utils = require "st.utils"

local zcl_clusters = require "st.zigbee.zcl.clusters"
local capabilities = require "st.capabilities"

local signal = require "signal-metrics"

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
  can_handle = require('moes.can_handle'),
}

return moes_sensor
