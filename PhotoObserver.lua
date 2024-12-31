-- PhotoObserver.lua

local LrApplication = import 'LrApplication'
local LrTasks       = import 'LrTasks'
local LrLogger      = import 'LrLogger'

-- Inicializa o logger
local logger = LrLogger("PhotoObserver")
logger:enable("print")  -- Exibe logs no console do Lightroom (Janela > Mostrar Log do Plugin)

-------------------------------------------------------------------------------
-- Função auxiliar para adicionar/remover keywords
-------------------------------------------------------------------------------
local function ensureKeyword(photo, keywordName, shouldHaveKeyword)
    logger:info(
        string.format(
            "ensureKeyword chamado para '%s'; Foto: %s",
            keywordName,
            photo:getPath() or "Caminho desconhecido"
        )
    )

    local catalog = LrApplication.activeCatalog()

    catalog:withWriteAccessDo("Ensure " .. keywordName .. " Keyword", function()
        local keywords = photo:getRawMetadata("keywordTags")
        local foundKeyword = nil

        -- Verifica se a keyword já existe
        for _, kw in ipairs(keywords) do
            if kw:getName() == keywordName then
                foundKeyword = kw
                break
            end
        end

        if shouldHaveKeyword then
            -- Se devemos ter a keyword mas ela não foi encontrada, cria e adiciona
            if not foundKeyword then
                logger:info("Adicionando keyword '" .. keywordName .. "'.")
                local newKeyword = catalog:createKeyword(keywordName, {}, true, nil, true)
                photo:addKeyword(newKeyword)
            else
                logger:debug("Keyword '" .. keywordName .. "' já existe.")
            end
        else
            -- Se NÃO devemos ter a keyword mas ela existe, remove
            if foundKeyword then
                logger:info("Removendo keyword '" .. keywordName .. "'.")
                photo:removeKeyword(foundKeyword)
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- Função que monitora mudanças no status de bandeira (flagStatus)
-------------------------------------------------------------------------------
local function monitorFlagging()
    logger:info("monitorFlagging iniciou.")
    local catalog = LrApplication.activeCatalog()

    -- Adiciona um observador ao catálogo para monitorar "flagStatus" de cada foto
    catalog:addPhotoPropertyChangeObserver("flagStatus", function(photo, propertyName)
        if propertyName == "flagStatus" then
            local flagState = photo:getFlagState() -- "flagged", "unflagged" ou "rejected"
            logger:debug("Flag state mudou para: " .. tostring(flagState))

            if flagState == "flagged" then
                -- Foto sinalizada
                ensureKeyword(photo, "Bandeirada", true)
                ensureKeyword(photo, "Rejeitada", false)
            elseif flagState == "rejected" then
                -- Foto rejeitada
                ensureKeyword(photo, "Bandeirada", false)
                ensureKeyword(photo, "Rejeitada", true)
            else
                -- Foto sem sinalização
                ensureKeyword(photo, "Bandeirada", false)
                ensureKeyword(photo, "Rejeitada", false)
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- Inicia a tarefa assíncrona para executar o monitoramento
-------------------------------------------------------------------------------
LrTasks.startAsyncTask(function()
    logger:info("Iniciando task assíncrona para monitorFlagging.")
    monitorFlagging()
end)
