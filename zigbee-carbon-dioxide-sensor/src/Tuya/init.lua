local capabilities = require "st.capabilities"
local data_types = require "st.zigbee.data_types"
local zb_utils = require "st.zigbee.utils"
local utils = require "st.utils"
local log = require "log"
local signal = require "signal-metrics"

local PREV_REPORTED_TIME = "reportedTime"

local TUYA_CARBON_DIOXIDE_FINGERPRINTS = {
    { mfr = "_TZE200_ogkdpgy2", model = "TS0601" },
    { mfr = "_TZE204_ogkdpgy2", model = "TS0601" },
}

local is_tuya_carbon_dioxide = function(opts, driver, device)
    -- log.debug("is_tuya_carbon_dioxide called: MFG=" .. device:get_manufacturer() .. "MODEL=" .. device:get_model())
    for _, fingerprint in ipairs(TUYA_CARBON_DIOXIDE_FINGERPRINTS) do
        if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
            return true
        end
    end

    return false
end

-----------------------------------------------------------
--- Tuya Custom Cluster ID
-----------------------------------------------------------
local TUYA_CLUSTER_ID = 0xEF00

-----------------------------------------------------------
--- Tuya Cluster Commands
-----------------------------------------------------------
local TUYA_SET_DATA_RESPONSE = 0x02

-----------------------------------------------------------
--- Tuya Data Points
-----------------------------------------------------------
local TUAY_AIR_QUALITY_CO2 = 0x02

--- Handler for the cluster specific command TY_DATA_REPORT on the Tuya private cluster
---
--- @param driver Driver The current driver running containing necessary context for execution
--- @param device ZigbeeDevice The device this message was received from containing identifying information
--- @param zb_rx ZigbeeMessageRx the Zigbee message received
local tuya_data_report_handler = function(driver, device, zb_rx)
    -- log.debug("tuya_data_report_handler called")
    -- log.debug("zb_rx.body.zcl_body.body_bytes: " .. zb_rx.body.zcl_body.body_bytes)
    local body_bytes = zb_rx.body.zcl_body.body_bytes
    local dpid = body_bytes:byte(3)
    -- log.debug("DPID: " .. dpid)
    if dpid == TUAY_AIR_QUALITY_CO2 then
        local co2 = utils.deserialize_int(body_bytes:sub(7, 10), 4, false, false)
        -- log.debug("CO2: " .. co2)
        local current_time = os.time()
        local prev_reported_time = device:get_field(PREV_REPORTED_TIME) or 0
        local prev_reported_value = device.state_cache.main and device.state_cache.main.carbonDioxideMeasurement.carbonDioxide.value or 0
        local mininum_report_interval = device.preferences.timeIntervalToReport or 60
        local minimum_report_changes = device.preferences.minimumReportChanges or 20
        if current_time - prev_reported_time > mininum_report_interval or math.abs( prev_reported_value - co2) > minimum_report_changes then
            device:emit_event(capabilities.carbonDioxideMeasurement.carbonDioxide(co2))
            device:set_field(PREV_REPORTED_TIME, current_time)
        end
    else
        log.info("tuya_data_report_handler: unknown dpid received (" .. dpid .. ")")
    end
end

local tuya_carbon_dioxide = {
    NAME = "Tuya Carbon Dioxide",
    zigbee_handlers = {
        cluster = {
            [TUYA_CLUSTER_ID] = {
                [TUYA_SET_DATA_RESPONSE] = {tuya_data_report_handler, signal.metrics_cluster}
            }
        }
    },
    can_handle = is_tuya_carbon_dioxide
}

return tuya_carbon_dioxide
