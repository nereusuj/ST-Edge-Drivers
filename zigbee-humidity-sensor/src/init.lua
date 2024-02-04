-- Copyright 2022 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local capabilities = require "st.capabilities"
local ZigbeeDriver = require "st.zigbee"
local clusters = require "st.zigbee.zcl.clusters"
local temperatureCluster = clusters.TemperatureMeasurement
local humidityCluster = clusters.RelativeHumidity
local defaults = require "st.zigbee.defaults"
local configurationMap = require "configurations"
local signal = require "signal-metrics"

local function device_init(driver, device)
  local configuration = configurationMap.get_device_configuration(device)
  if configuration ~= nil then
    for _, attribute in ipairs(configuration) do
      device:add_configured_attribute(attribute)
      device:add_monitored_attribute(attribute)
    end
  end
end

local function concat_handlers(handler_1, handler_2)
  local handlers = (type(handler_1) == "table") and handler_1 or { handler_1 }
  table.insert(handlers, handler_2)
  return handlers
end

local zigbee_humidity_driver = {
  supported_capabilities = {
    capabilities.battery,
    capabilities.relativeHumidityMeasurement,
    capabilities.temperatureMeasurement
  },
  zigbee_handlers = {
    attr = {
      [clusters.Basic.ID] = {
        [clusters.Basic.attributes.ZCLVersion.ID] = signal.metrics
      },
    },
  },
  lifecycle_handlers = {
    init = device_init
  },
  sub_drivers = {
    require("aqara"),
    require("plant-link"),
    require("plaid-systems"),
    require("centralite-sensor"),
    require("heiman-sensor"),
    require("frient-sensor"),
    require("moes")
  }
}

defaults.register_for_default_handlers(zigbee_humidity_driver, zigbee_humidity_driver.supported_capabilities)

-- Add signal.metrics handler to the default handlers
zigbee_humidity_driver.zigbee_handlers.attr[temperatureCluster.ID]
  [temperatureCluster.attributes.MeasuredValue.ID] =
  concat_handlers(zigbee_humidity_driver.zigbee_handlers.attr[temperatureCluster.ID]
    [temperatureCluster.attributes.MeasuredValue.ID], signal.metrics)
zigbee_humidity_driver.zigbee_handlers.attr[humidityCluster.ID]
  [humidityCluster.attributes.MeasuredValue.ID] =
  concat_handlers(zigbee_humidity_driver.zigbee_handlers.attr[humidityCluster.ID]
    [humidityCluster.attributes.MeasuredValue.ID], signal.metrics)

local driver = ZigbeeDriver("zigbee-humidity-sensor", zigbee_humidity_driver)
driver:run()
