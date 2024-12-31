local LrApplication = import "LrApplication"
local LrTasks = import "LrTasks"
local LrDialogs = import "LrDialogs"
local LrLogger = import "LrLogger"

-- Configurar Logger
local logger = LrLogger("FlagMonitorLogger")
logger:enable("logfile") -- Salva em arquivo de log
logger:enable("print")   -- Exibe no console (terminal)

local function showDialog(message)
    LrDialogs.message("Flag Monitor", message, "info")
end

-- Função para adicionar palavra-chave
local function addFlagKeyword(photo)
    local catalog = LrApplication.activeCatalog()
    catalog:withWriteAccessDo("Adicionar Palavra-Chave", function()
        local keywords = photo:getRawMetadata("keywordTags")
        local alreadyTagged = false
        
        -- Verificar se a palavra-chave já existe
        for _, keyword in ipairs(keywords) do
            if keyword:getName() == "Bandeirada" then
                alreadyTagged = true
                break
            end
        end
        
        -- Se não existe, adicionar a palavra-chave
        if not alreadyTagged then
            local keyword = catalog:createKeyword("Bandeirada", {}, true, nil, true)
            photo:addKeyword(keyword)
            logger:info("Palavra-chave 'Bandeirada' adicionada à foto.")
            showDialog("Palavra-chave 'Bandeirada' adicionada à foto.")
        else
            logger:info("Palavra-chave 'Bandeirada' já existe.")
            showDialog("Palavra-chave 'Bandeirada' já está presente.")
        end
    end)
end

-- Função principal de monitoramento
local function monitorFlagging()
    showDialog("Inicializando addFlagKeyword...")
    logger:info("Monitoramento de bandeiramento iniciado.")
    local catalog = LrApplication.activeCatalog()
    
    -- Observador de mudanças nas fotos
    catalog:addPhotoPropertyChangeObserver("flagged", function(eventContext, photo)
        local flagStatus = photo:getRawMetadata("flagged")
        logger:info("Mudança detectada na foto: " .. photo:getFormattedMetadata("fileName"))
        logger:info("Status de bandeiramento: " .. tostring(flagStatus))


        if flagStatus then
            addFlagKeyword(photo)
        end
    end)
    
    logger:info("Monitoramento de bandeiramento iniciado.")
end

-- Iniciar Monitoramento
monitorFlagging()
