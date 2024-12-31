local PhotoObserver = require "PhotoObserver"

local function initPlugin()
  PhotoObserver.startMonitoring()
end

return {
  startPlugin = initPlugin
}