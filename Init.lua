local PhotoObserver = require "PhotoObserver"
local LrDialogs = import "LrDialogs"

local function initPlugin()
  PhotoObserver.startMonitoring()
  LrDialogs.message("Plugin carregado corretamente.", "O plugin foi carregado com sucesso.", "info")
end

return {
  startPlugin = initPlugin
}