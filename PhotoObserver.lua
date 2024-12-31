local LrTasks = import "LrTasks"
local LrLogger = import "LrLogger"
local LrApplication = import "LrApplication"
local catalog = LrApplication.activeCatalog()

-- Cria um logger para debug (opcional)
local logger = LrLogger("PhotoObserver")
logger:enable("logfile")

-- Nome da palavra-chave que queremos atribuir
local KEYWORD_TO_ADD = "Bandeirada"

-- Função principal que fará a verificação
local function checkFlagAndAddKeyword()
  catalog:withWriteAccessDo("Check Flag", function()
    -- Pega as fotos que estão selecionadas (por exemplo)
    local selectedPhotos = catalog:getTargetPhotos()
    for _, photo in ipairs(selectedPhotos) do
      -- Lê o status de bandeira da foto
      local flag = photo:getRawMetadata("pickStatus")
      -- Valores possíveis: 
      --   0 = sem bandeira, 
      --   1 = bandeirada (Pick), 
      --  -1 = rejeitada (Reject)

      if flag == 1 then
        -- Se for bandeirada, adiciona a palavra-chave
        addKeywordToPhoto(photo, KEYWORD_TO_ADD)
      end
    end
  end)
end

-- Função auxiliar para adicionar a palavra-chave
function addKeywordToPhoto(photo, keywordName)
  local keyword = findOrCreateKeyword(keywordName)
  if keyword then
    local currentKeywords = photo:getRawMetadata("keywords")
    -- Verifica se já existe para evitar duplicar
    local alreadyHasKeyword = false
    for _, kw in ipairs(currentKeywords) do
      if kw:getName() == keywordName then
        alreadyHasKeyword = true
        break
      end
    end

    if not alreadyHasKeyword then
      photo:addKeyword(keyword)
      logger:trace("Palavra-chave '"..keywordName.."' adicionada à foto.")
    end
  end
end

-- Função para encontrar ou criar uma palavra-chave
function findOrCreateKeyword(keywordName)
  local keyword = catalog:findKeywordByName(keywordName)
  if not keyword then
    keyword = catalog:createKeyword(keywordName, {}, true, nil, true)
  end
  return keyword
end

-- Rotina que o Lightroom chamará quando o plugin iniciar
local function startMonitoring()
  LrTasks.startAsyncTask(function()
    -- Nesse loop simples, executamos a checagem a cada X segundos.
    -- Em produção, pode ser otimizável para só disparar manualmente
    -- ou conforme a lógica que você preferir.
    while true do
      checkFlagAndAddKeyword()
      LrTasks.sleep(5) -- verifica a cada 5 segundos (exemplo)
    end
  end)
end

return {
  startMonitoring = startMonitoring
}
