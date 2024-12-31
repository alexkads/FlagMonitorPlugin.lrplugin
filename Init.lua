-- Importa o módulo responsável pelo monitoramento de fotos
local PhotoObserver = require "PhotoObserver"
local LrDialogs = import "LrDialogs"

--- Função de inicialização do plugin
local function initPlugin()
  -- Inicia o monitoramento automático ao carregar o Lightroom
  PhotoObserver.startMonitoring()
  
  -- Mensagem de confirmação para o usuário
  LrDialogs.message(
    "Plugin Carregado Corretamente",
    "O plugin foi carregado com sucesso e o monitoramento foi iniciado.",
    "info"
  )
end

-- Retorna a função de inicialização para ser chamada pelo Lightroom
return {
  startPlugin = initPlugin
}
