local ZigbeeDriver = require "st.zigbee"
local capabilities = require "st.capabilities"
local defaults = require "st.zigbee.defaults"
local constants = require "st.zigbee.constants"

--Carbon Dioxide Measurement
local zigbee_carbon_dioxide_driver_template = {
    supported_capabilities = {
        capabilities.carbonDioxideMeasurement,
    },
    ias_zone_configuration_method = constants.IAS_ZONE_CONFIGURE_TYPE.AUTO_ENROLL_RESPONSE,
    sub_drivers = { require("Tuya") }
}

defaults.register_for_default_handlers(zigbee_carbon_dioxide_driver_template, zigbee_carbon_dioxide_driver_template.supported_capabilities)
local zigbee_carbon_dioxide_driver = ZigbeeDriver("zigbee-carbon-dioxide-sensor", zigbee_carbon_dioxide_driver_template)
zigbee_carbon_dioxide_driver:run()
