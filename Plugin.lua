local LrApplication = import 'LrApplication'
local LrTasks       = import 'LrTasks'

-- Adiciona a keyword "Bandeirada" se ela não existir
local function addFlagKeyword(photo)
    local catalog = LrApplication.activeCatalog()
    catalog:withWriteAccessDo("Add Bandeirada Keyword", function()
        local keywords = photo:getRawMetadata("keywordTags")
        local alreadyTagged = false

        for _, kw in ipairs(keywords) do
            if kw:getName() == "Bandeirada" then
                alreadyTagged = true
                break
            end
        end

        if not alreadyTagged then
            local bandeiradaKeyword = catalog:createKeyword("Bandeirada", {}, true, nil, true)
            photo:addKeyword(bandeiradaKeyword)
        end
    end)
end

-- Adiciona a keyword "Rejeitada" se ela não existir
local function addRejectedKeyword(photo)
    local catalog = LrApplication.activeCatalog()
    catalog:withWriteAccessDo("Add Rejeitada Keyword", function()
        local keywords = photo:getRawMetadata("keywordTags")
        local alreadyTagged = false

        for _, kw in ipairs(keywords) do
            if kw:getName() == "Rejeitada" then
                alreadyTagged = true
                break
            end
        end

        if not alreadyTagged then
            local rejeitadaKeyword = catalog:createKeyword("Rejeitada", {}, true, nil, true)
            photo:addKeyword(rejeitadaKeyword)
        end
    end)
end

-- Remove a keyword "Bandeirada"
local function removeFlagKeyword(photo)
    local catalog = LrApplication.activeCatalog()
    catalog:withWriteAccessDo("Remove Bandeirada Keyword", function()
        local keywords = photo:getRawMetadata("keywordTags")
        for _, kw in ipairs(keywords) do
            if kw:getName() == "Bandeirada" then
                photo:removeKeyword(kw)
                break
            end
        end
    end)
end

-- Remove a keyword "Rejeitada"
local function removeRejectedKeyword(photo)
    local catalog = LrApplication.activeCatalog()
    catalog:withWriteAccessDo("Remove Rejeitada Keyword", function()
        local keywords = photo:getRawMetadata("keywordTags")
        for _, kw in ipairs(keywords) do
            if kw:getName() == "Rejeitada" then
                photo:removeKeyword(kw)
                break
            end
        end
    end)
end

-- Função que monitora mudanças no status da bandeira
local function monitorFlagging()
    local catalog = LrApplication.activeCatalog()

    catalog:addPhotoPropertyChangeObserver("flagStatus", function(photo, propertyName)
        if propertyName == "flagStatus" then
            local flagState = photo:getFlagState() -- Valores: "flagged", "unflagged", "rejected"

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
    monitorFlagging()
end)
