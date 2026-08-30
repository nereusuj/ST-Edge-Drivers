-- local log = require "log"

local is_moes_products = function(opts, driver, device)
  local FINGERPRINTS = require("moes.fingerprints")
  for _, fingerprint in ipairs(FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
    --   log.debug("MOES Temperature and Humidity Sensor fingerprint matched: MFG=" .. device:get_manufacturer() .. " MODEL=" .. device:get_model())
      return true, require("moes")
    end
  end
  return false
end

return is_moes_products
