local LrApplication = import 'LrApplication'
local LrTasks       = import 'LrTasks'

-- Cria / adiciona a keyword "Bandeirada" se ela não existir na foto
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
            -- Cria a keyword "Bandeirada" (caso não exista)
            local bandeiradaKeyword = catalog:createKeyword("Bandeirada", {}, true, nil, true)
            -- Adiciona a keyword à foto
            photo:addKeyword(bandeiradaKeyword)
        end
    end)
end

-- Remove a keyword "Bandeirada" da foto, se existir
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

-- Função que configura o observador para detectar mudança de bandeira
local function monitorFlagging()
    local catalog = LrApplication.activeCatalog()

    -- Observa mudanças na propriedade "flagStatus" das fotos
    catalog:addPhotoPropertyChangeObserver("flagStatus", function(photo, propertyName)
        -- Garantir que estamos reagindo apenas a mudanca de flagStatus
        if propertyName == "flagStatus" then
            -- Verifica o status da bandeira. Pode retornar "flagged", "unflagged" ou "rejected"
            local flagState = photo:getFlagState()  -- ou photo:getRawMetadata("flagStatus")

            if flagState == "flagged" then
                addFlagKeyword(photo)
            else
                -- Se não estiver "flagged", removemos a keyword
                -- (você pode filtrar se quiser remover só quando "unflagged" e ignorar "rejected", por exemplo)
                removeFlagKeyword(photo)
            end
        end
    end)
end

-- Usamos uma tarefa assíncrona para iniciar o monitoramento de forma segura
LrTasks.startAsyncTask(function()
    monitorFlagging()
end)
