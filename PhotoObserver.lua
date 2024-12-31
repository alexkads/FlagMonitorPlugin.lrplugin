local LrTasks        = import "LrTasks"
local LrLogger       = import "LrLogger"
local LrApplication  = import "LrApplication"

local catalog = LrApplication.activeCatalog()

local logger = LrLogger("PhotoObserver")
logger:enable("logfile")
logger:enable("print")

local KEYWORD_TO_ADD = "Comprada"

-- Função para remover a palavra-chave
function removeKeywordFromPhoto(photo, keywordName)
  local currentKeywords = photo:getRawMetadata("keywords")
  for _, kw in ipairs(currentKeywords) do
    if kw:getName() == keywordName then
      photo:removeKeyword(kw)
      logger:trace("Palavra-chave '" .. keywordName .. "' removida da foto.")
      break
    end
  end
end

-- Função para adicionar a palavra-chave
function addKeywordToPhoto(photo, keywordName)
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
      logger:trace("Palavra-chave '" .. keywordName .. "' adicionada à foto.")
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

-- Função principal que fará a checagem de bandeira
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

-- Rotina chamada quando o plugin inicia
local function startMonitoring()
  logger:trace("Plugin carregado corretamente.")
  LrTasks.startAsyncTask(function()
    while true do
      checkFlagAndAddKeyword()
      LrTasks.sleep(5)
    end
  end)
end

return {
  startMonitoring = startMonitoring
}