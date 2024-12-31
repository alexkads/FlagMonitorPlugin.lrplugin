local LrApplication = import "LrApplication"
local LrTasks = import "LrTasks"

-- Função para adicionar a palavra-chave "Bandeirada"
local function addFlagKeyword(photo)
    local catalog = LrApplication.activeCatalog()
    catalog:withWriteAccessDo("Adicionar Palavra-Chave", function()
        local keywords = photo:getRawMetadata("keywordTags")
        local alreadyTagged = false

        -- Verificar se a palavra-chave "Bandeirada" já existe
        for _, keyword in ipairs(keywords) do
            if keyword:getName() == "Bandeirada" then
                alreadyTagged = true
                break
            end
        end

        -- Se não existe, criar e adicionar a palavra-chave
        if not alreadyTagged then
            local keyword = catalog:createKeyword("Bandeirada", {}, true, nil, true)
            photo:addKeyword(keyword)
        end
    end)
end

-- Função para remover a palavra-chave "Bandeirada"
local function removeFlagKeyword(photo)
    local catalog = LrApplication.activeCatalog()
    catalog:withWriteAccessDo("Remover Palavra-Chave", function()
        local keywords = photo:getRawMetadata("keywordTags")

        for _, keyword in ipairs(keywords) do
            if keyword:getName() == "Bandeirada" then
                photo:removeKeyword(keyword)
                break
            end
        end
    end)
end

-- Função principal de monitoramento
local function monitorFlagging()
    local catalog = LrApplication.activeCatalog()

    -- Observador de mudanças na propriedade "flagged" das fotos
    catalog:addPhotoPropertyChangeObserver("flagged", function(photo, changedProperty)
        -- Verifica se a propriedade alterada foi mesmo "flagged"
        if changedProperty ~= "flagged" then
            return
        end

        -- Retorna true se a foto está bandeirada, false caso contrário
        local flagStatus = photo:getRawMetadata("flagged")

        if flagStatus then
            addFlagKeyword(photo)
        else
            removeFlagKeyword(photo)
        end
    end)
end

-- Iniciar Monitoramento
monitorFlagging()
