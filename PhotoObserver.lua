-- PhotoObserver.lua

local LrApplication = import 'LrApplication'
local LrTasks       = import 'LrTasks'
local LrLogger      = import 'LrLogger'
local LrCatalog     = import 'LrCatalog'

-- Inicializa o logger
local logger = LrLogger("PhotoObserver")
logger:enable("print")  -- Exibe logs no console do Lightroom (Janela > Mostrar Log do Plugin)

-------------------------------------------------------------------------------
-- Função auxiliar para adicionar/remover keywords
-------------------------------------------------------------------------------
local function ensureKeyword(photo, keywordName, shouldHaveKeyword)
    logger:info("Iniciando ensureKeyword para '" .. keywordName .. "'; Foto: " .. (photo:getPath() or "Caminho desconhecido"))

    local catalog = LrApplication.activeCatalog()

    if not catalog then
        logger:error("Catálogo ativo não encontrado.")
        return
    end

    catalog:withWriteAccessDo("Ensure " .. keywordName .. " Keyword", function()
        logger:info("Dentro de withWriteAccessDo para '" .. keywordName .. "'")
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

    logger:info("Finalizando ensureKeyword para '" .. keywordName .. "'")
end

-------------------------------------------------------------------------------
-- Função que monitora mudanças no status de bandeira (flagStatus)
-------------------------------------------------------------------------------
local function monitorFlagging()
    logger:info("Iniciando monitorFlagging.")
    local catalog = LrApplication.activeCatalog()

    if not catalog then
        logger:error("Catálogo ativo não encontrado.")
        return
    end

    -- Adiciona um observador ao catálogo para monitorar "flagStatus" de cada foto
    catalog:addObserver("flagStatus", function(eventContext)
        logger:info("Observador de flagStatus acionado.")
        local photo = eventContext.photo
        local propertyName = eventContext.propertyName

        if not photo then
            logger:error("Foto não encontrada no contexto do evento.")
            return
        end

        if propertyName == "flagStatus" then
            local flagState = photo:getFlagState() -- 1 (flagged), 0 (unflagged) ou -1 (rejected)
            if flagState == nil then
                logger:warn("Flag state é nil para a foto: " .. (photo:getPath() or "Caminho desconhecido"))
                return
            end
            logger:debug("Flag state mudou para: " .. tostring(flagState))

            if flagState == 1 then
                -- Foto sinalizada
                ensureKeyword(photo, "Bandeirada", true)
                ensureKeyword(photo, "Rejeitada", false)
            elseif flagState == -1 then
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

    logger:info("Finalizando monitorFlagging.")
end

-------------------------------------------------------------------------------
-- Inicia a tarefa assíncrona para executar o monitoramento
-------------------------------------------------------------------------------
LrTasks.startAsyncTask(function()
    logger:info("Iniciando task assíncrona para monitorFlagging.")
    monitorFlagging()
end)