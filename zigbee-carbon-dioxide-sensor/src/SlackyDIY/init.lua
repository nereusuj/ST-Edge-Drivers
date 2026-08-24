local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local cluster_base = require "st.zigbee.cluster_base"
local log = require "log"

local SLACKY_CARBON_DIOXIDE_FINGERPRINTS = {
    { mfr = "Slacky-DIY", model = "Tuya_CO2Sensor_r01" },
    { mfr = "Slacky-DIY", model = "Tuya_CO2Sensor_r02" },
}

--- Checks if the device is a Slacky DIY Carbon Dioxide Sensor based on its manufacturer and model.
--- This function iterates through a predefined list of fingerprints and compares the device's manufacturer and model
--- to determine if it matches any of the known Slacky DIY Carbon Dioxide Sensor fingerprints.
---
--- @param opts table Options for the device handler
--- @param driver Driver The current driver running containing necessary context for execution
--- @param device ZigbeeDevice The device this message was received from containing identifying information
--- @return boolean Returns true if the device matches a Slacky DIY Carbon Dioxide Sensor fingerprint,
local is_slacky_carbon_dioxide = function(opts, driver, device)
    -- log.debug("is_slacky_carbon_dioxide called: MFG=" .. device:get_manufacturer() .. " MODEL=" .. device:get_model())
    for _, fingerprint in ipairs(SLACKY_CARBON_DIOXIDE_FINGERPRINTS) do
        if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
            return true
        end
    end

    return false
end

-----------------------------------------------------------
--- Carbon Dioxide Cluster ID
-----------------------------------------------------------
local ZCL_CLUSTER_MS_CO2_MEASUREMENT = 0x040D

-----------------------------------------------------------
--- Carbon Dioxide Cluster Commands
-----------------------------------------------------------
local ZCL_CO2_MEASUREMENT_ATTRIB_MEASUREDVALUE = 0x0000

--- Configuration for reporting the CO2 Measurement attribute.
local configuration = {
    {
        cluster = ZCL_CLUSTER_MS_CO2_MEASUREMENT,
        attribute = ZCL_CO2_MEASUREMENT_ATTRIB_MEASUREDVALUE,
        minimum_interval = 60,
        maximum_interval = 1200,
        data_type = data_types.SinglePrecisionFloat,
        reportable_change = data_types.SinglePrecisionFloat(0, -17, 0.31072)
    },
}

--- Converts a numeric value to a Zigbee Cluster Library (ZCL) Single Precision Float data type.
--- This function takes a numeric value and converts it into the ZCL Single Precision Float format,
--- which consists of a sign bit, an exponent, and a mantissa.
--- The conversion is based on the IEEE 754 standard for floating-point arithmetic.
---
--- @param value number The numeric value to be converted to ZCL Single Precision Float.
--- @return SinglePrecisionFloat The converted value in ZCL Single Precision Float format.
local function to_zcl_float(value)
    if value == 0 then
        return data_types.SinglePrecisionFloat(0, 0, 0)
    end

    local sign = value < 0 and 1 or 0
    local abs_value = math.abs(value)

    local m, e = math.frexp(abs_value)

    return data_types.SinglePrecisionFloat(
        sign,
        e - 1,
        m * 2 - 1
    )
end

--- Initializes the device by configuring the reporting for the CO2 Measurement attribute.
--- This function is called during the device's initialization phase.
--- It sets up the reporting intervals and thresholds based on the device's preferences or default values.
---
--- @param driver Driver The current driver running containing necessary context for execution
--- @param device ZigbeeDevice The device this message was received from containing identifying information
local function device_init(driver, device)
    log.debug("device_init called for device")
    if configuration ~= nil then
        for _, attribute in ipairs(configuration) do
            local attribute_with_preferences = {
                cluster = attribute.cluster,
                attribute = attribute.attribute,
                minimum_interval = device.preferences.minimumReportInterval or attribute.minimum_interval,
                maximum_interval = device.preferences.maximumReportInterval or attribute.maximum_interval,
                data_type = attribute.data_type,
                reportable_change =
                    (device.preferences.minimumReportChanges and to_zcl_float(device.preferences.minimumReportChanges * 0.000001)) or
                        attribute.reportable_change
            }
            device:add_configured_attribute(attribute_with_preferences)
        end
    end
end

--- Handler for the infoChanged lifecycle event.
--- This function is called when the device's preferences are changed.
--- It updates the reporting configuration for the CO2 Measurement attribute based on the new preferences.
---
--- @param driver Driver The current driver running containing necessary context for execution
--- @param device ZigbeeDevice The device this message was received from containing identifying information
--- @param event LifecycleEvent The lifecycle event that triggered this handler
--- @param args table Additional arguments passed to the handler
local function info_changed(driver, device, event, args)
    log.debug("info_changed called for device")
    local min_report_interval = device.preferences.minimumReportInterval or 60
    local max_report_interval = device.preferences.maximumReportInterval or 1200
    local min_report_changes = device.preferences.minimumReportChanges or 10
    log.debug("info_changed: max_report_interval=" .. max_report_interval .. ", min_report_interval=" .. min_report_interval .. ", min_report_changes=" .. min_report_changes)
    device:send(cluster_base.configure_reporting(
        device,
        data_types.ClusterId(ZCL_CLUSTER_MS_CO2_MEASUREMENT),
        data_types.AttributeId(ZCL_CO2_MEASUREMENT_ATTRIB_MEASUREDVALUE),
        data_types.SinglePrecisionFloat.ID,
        min_report_interval,
        max_report_interval,
        to_zcl_float(min_report_changes * 0.000001))
    )
    log.debug("info_changed: configure_reporting sent for CO2 Measurement attribute")
end

--- Handler for the CO2 Measurement attribute report.
--- This function is called when the device sends a report for the measured CO2 value.
--- It checks if the reported value should be emitted based on the configured reporting intervals and thresholds.
---
--- @param driver Driver The current driver running containing necessary context for execution
--- @param device ZigbeeDevice The device this message was received from containing identifying information
--- @param value The attribute value
--- @param zb_rx ZigbeeMessageRx the Zigbee message received
local function carbonDioxide_attr_handler(driver, device, value, zb_rx)
    -- log.debug("carbonDioxide_attr_handler called")
    local co2 = value.value * 1000000
    -- log.debug("CO2: " .. co2)
    device:emit_event(capabilities.carbonDioxideMeasurement.carbonDioxide(co2))
end

local slacky_carbon_dioxide = {
    NAME = "Slacky DIY Carbon Dioxide",
    zigbee_handlers = {
        attr = {
            [ZCL_CLUSTER_MS_CO2_MEASUREMENT] = {
                [ZCL_CO2_MEASUREMENT_ATTRIB_MEASUREDVALUE] = carbonDioxide_attr_handler
            }
        }
    },
    lifecycle_handlers = {
        init = device_init,
        infoChanged = info_changed
    },
    can_handle = is_slacky_carbon_dioxide
}

return slacky_carbon_dioxide
