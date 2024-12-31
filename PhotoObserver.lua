local LrApplication = import 'LrApplication'
local LrTasks       = import 'LrTasks'
local LrLogger = import 'LrLogger' -- Added logger import
local logger = LrLogger("PhotoObserver") -- Initialized logger
logger:enable("print") -- Enabled logging

-- Adiciona a keyword "Bandeirada" se ela não existir
local function addFlagKeyword(photo)
    logger:info("addFlagKeyword called for photo: " .. photo:getPath()) -- Added log
    local catalog = LrApplication.activeCatalog()
    catalog:withWriteAccessDo("Add Bandeirada Keyword", function()
        local keywords = photo:getRawMetadata("keywordTags")
        local alreadyTagged = false

        for _, kw in ipairs(keywords) do
            if kw:getName() == "Bandeirada" then
                alreadyTagged = true
                logger:debug("'Bandeirada' keyword already exists.") -- Added log
                break
            end
        end

        if not alreadyTagged then
            logger:info("Adding 'Bandeirada' keyword.") -- Added log
            local bandeiradaKeyword = catalog:createKeyword("Bandeirada", {}, true, nil, true)
            photo:addKeyword(bandeiradaKeyword)
        end
    end)
end

-- Adiciona a keyword "Rejeitada" se ela não existir
local function addRejectedKeyword(photo)
    logger:info("addRejectedKeyword called for photo: " .. photo:getPath()) -- Added log
    local catalog = LrApplication.activeCatalog()
    catalog:withWriteAccessDo("Add Rejeitada Keyword", function()
        local keywords = photo:getRawMetadata("keywordTags")
        local alreadyTagged = false

        for _, kw in ipairs(keywords) do
            if kw:getName() == "Rejeitada" then
                alreadyTagged = true
                logger:debug("'Rejeitada' keyword already exists.") -- Added log
                break
            end
        end

        if not alreadyTagged then
            logger:info("Adding 'Rejeitada' keyword.") -- Added log
            local rejeitadaKeyword = catalog:createKeyword("Rejeitada", {}, true, nil, true)
            photo:addKeyword(rejeitadaKeyword)
        end
    end)
end

-- Remove a keyword "Bandeirada"
local function removeFlagKeyword(photo)
    logger:info("removeFlagKeyword called for photo: " .. photo:getPath()) -- Added log
    local catalog = LrApplication.activeCatalog()
    catalog:withWriteAccessDo("Remove Bandeirada Keyword", function()
        local keywords = photo:getRawMetadata("keywordTags")
        for _, kw in ipairs(keywords) do
            if kw:getName() == "Bandeirada" then
                logger:info("Removing 'Bandeirada' keyword.") -- Added log
                photo:removeKeyword(kw)
                break
            end
        end
    end)
end

-- Remove a keyword "Rejeitada"
local function removeRejectedKeyword(photo)
    logger:info("removeRejectedKeyword called for photo: " .. photo:getPath()) -- Added log
    local catalog = LrApplication.activeCatalog()
    catalog:withWriteAccessDo("Remove Rejeitada Keyword", function()
        local keywords = photo:getRawMetadata("keywordTags")
        for _, kw in ipairs(keywords) do
            if kw:getName() == "Rejeitada" then
                logger:info("Removing 'Rejeitada' keyword.") -- Added log
                photo:removeKeyword(kw)
                break
            end
        end
    end)
end

-- Função que monitora mudanças no status da bandeira
local function monitorFlagging()
    logger:info("monitorFlagging started.") -- Added log
    local catalog = LrApplication.activeCatalog()

    catalog:addPhotoPropertyChangeObserver("flagStatus", function(photo, propertyName)
        if propertyName == "flagStatus" then
            local flagState = photo:getFlagState() -- Valores: "flagged", "unflagged", "rejected"
            logger:debug("Flag state changed to: " .. flagState) -- Added log

            if flagState == "flagged" then
                addFlagKeyword(photo)
                removeRejectedKeyword(photo) -- Garante que "Rejeitada" seja removida
            elseif flagState == "rejected" then
                addRejectedKeyword(photo)
                removeFlagKeyword(photo) -- Garante que "Bandeirada" seja removida
            else
                -- Caso não esteja flagged ou rejected, remove ambas as keywords
                removeFlagKeyword(photo)
                removeRejectedKeyword(photo)
            end
        end
    end)
end

-- Inicia o monitoramento em uma tarefa assíncrona
LrTasks.startAsyncTask(function()
    logger:info("Starting async task for monitorFlagging.") -- Added log
    monitorFlagging()
end)