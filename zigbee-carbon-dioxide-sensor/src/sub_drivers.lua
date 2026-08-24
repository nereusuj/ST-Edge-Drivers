local lazy_load_if_possible = require "lazy_load_subdriver"
local sub_drivers = {
   lazy_load_if_possible("Tuya"),
   lazy_load_if_possible("SlackyDIY"),
}
return sub_drivers
