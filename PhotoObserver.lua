--[[
------------------------------------------------------------------------
Plugin: Monitoramento de Bandeiras e Adição/Remoção de Palavra-Chave
Autor: Você
Data: xx/xx/xxxx
Descrição:
  - Monitora fotos selecionadas no Lightroom e adiciona ou remove a 
    palavra-chave "Comprada" de acordo com o status da bandeira (Pick, None, Reject).
  - Atualiza a cada intervalo configurado (CHECK_INTERVAL).
  - Inclui melhorias de logging, captura de erros e possibilidade de 
    iniciar/parar o monitoramento.
------------------------------------------------------------------------
]]

-- Import de Módulos do Lightroom
local LrTasks        = import "LrTasks"
local LrLogger       = import "LrLogger"
local LrApplication  = import "LrApplication"
local LrDialogs      = import "LrDialogs"

-- Catálogo ativo do Lightroom
local catalog = LrApplication.activeCatalog()

-- Logger
local logger = LrLogger("PhotoObserver")
-- Habilite estes modos conforme desejar. "logfile" gera arquivo de log externo.
-- "print" imprime no console do próprio Lightroom (janela de log).
logger:enable("logfile")
logger:enable("print")

-- =============================================================================
-- Configurações Gerais
-- =============================================================================

-- Palavra-chave a ser adicionada/removida caso a foto seja "Pick" ou não
local KEYWORD_TO_ADD = "Comprada"

-- Intervalo de checagem em segundos
local CHECK_INTERVAL = 5

-- Nível de log: "error", "warn", "info", "debug", "trace"
-- Ajuste para controlar a verbosidade
local LOG_LEVEL = "info"

-- Mapeamento de níveis para comparações
local LEVELS = { error = 1, warn = 2, info = 3, debug = 4, trace = 5 }

-- Variável de controle de monitoramento
local monitoring = false

-- =============================================================================
-- Funções de Log
-- =============================================================================

--- Função auxiliar para gerar logs com base no nível de log configurado
---@param level string Nível do log ("error", "warn", "info", "debug", "trace")
---@param message string Mensagem a ser registrada
local function log(level, message)
  if LEVELS[level] <= LEVELS[LOG_LEVEL] then
    logger:trace(string.format("[%s] %s", level:upper(), message))
  end
end

-- =============================================================================
-- Funções de Manipulação de Palavras-Chave
-- =============================================================================

--- Remove uma palavra-chave específica de uma foto
---@param photo LrPhoto Objeto LrPhoto
---@param keywordName string Nome da palavra-chave a ser removida
local function removeKeywordFromPhoto(photo, keywordName)
  local currentKeywords = photo:getRawMetadata("keywords")

  for _, kw in ipairs(currentKeywords) do
    if kw:getName() == keywordName then
      photo:removeKeyword(kw)
      log("info", "Palavra-chave '" .. keywordName .. "' removida da foto.")
      break
    end
  end
end

--- Adiciona uma palavra-chave específica a uma foto
---@param photo LrPhoto Objeto LrPhoto
---@param keywordName string Nome da palavra-chave a ser adicionada
local function addKeywordToPhoto(photo, keywordName)
  local keyword = findOrCreateKeyword(keywordName)
  if keyword then
    local currentKeywords = photo:getRawMetadata("keywords")
    local alreadyHasKeyword = false

    for _, kw in ipairs(currentKeywords) do
      if kw:getName() == keywordName then
        alreadyHasKeyword = true
        break
      end
    end

    if not alreadyHasKeyword then
      photo:addKeyword(keyword)
      log("info", "Palavra-chave '" .. keywordName .. "' adicionada à foto.")
    end
  end
end

--- Encontra ou cria uma palavra-chave no catálogo
---@param keywordName string Nome da palavra-chave
---@return LrKeyword Objeto LrKeyword
function findOrCreateKeyword(keywordName)
  local keyword = catalog:findKeywordByName(keywordName)
  if not keyword then
    keyword = catalog:createKeyword(keywordName, {}, true, nil, true)
    log("debug", "Palavra-chave '" .. keywordName .. "' criada no catálogo.")
  end
  return keyword
end

-- =============================================================================
-- Função Principal de Checagem
-- =============================================================================

--- Checa as bandeiras das fotos selecionadas e adiciona/remove a palavra-chave
local function checkFlagAndAddKeyword()
  catalog:withWriteAccessDo("Check Flag", function()
    local selectedPhotos = catalog:getTargetPhotos()

    for _, photo in ipairs(selectedPhotos) do
      local flag = photo:getRawMetadata("pickStatus")
      -- 0 = sem bandeira, 1 = bandeirada (Pick), -1 = rejeitada (Reject)

      if flag == 1 then
        addKeywordToPhoto(photo, KEYWORD_TO_ADD)
      else
        removeKeywordFromPhoto(photo, KEYWORD_TO_ADD)
      end
    end
  end)
end

-- =============================================================================
-- Controle de Monitoramento
-- =============================================================================

--- Inicia o monitoramento, se não estiver em andamento
local function startMonitoring()
  if monitoring then
    log("warn", "Monitoramento já está em andamento.")
    return
  end

  monitoring = true
  log("info", "Plugin: Monitoramento iniciado.")

  LrTasks.startAsyncTask(function()
    while monitoring do
      -- Protege a execução principal com pcall para capturar erros
      local ok, err = pcall(function()
        checkFlagAndAddKeyword()
      end)

      if not ok then
        log("error", "Erro durante a execução: " .. tostring(err))
      end

      -- Aguarda o intervalo configurado
      LrTasks.sleep(CHECK_INTERVAL)
    end
  end)
end

--- Para o monitoramento, se estiver em andamento
local function stopMonitoring()
  if not monitoring then
    log("warn", "Monitoramento não está ativo.")
    return
  end

  monitoring = false
  log("info", "Plugin: Monitoramento parado.")
end

-- =============================================================================
-- Retorna as funções de controle para uso externo
-- =============================================================================
return {
  startMonitoring = startMonitoring,
  stopMonitoring  = stopMonitoring
}
