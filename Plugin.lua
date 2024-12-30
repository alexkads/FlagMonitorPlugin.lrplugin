local LrApplication = import "LrApplication"
local LrTasks = import "LrTasks"
local LrDialogs = import "LrDialogs"

-- Função principal para monitorar alterações
local function monitorFlagging()
    LrTasks.startAsyncTask(function()
        local catalog = LrApplication.activeCatalog()
        
        while true do
            -- Obter fotos selecionadas
            local selectedPhotos = catalog:getTargetPhotos()
            
            for _, photo in ipairs(selectedPhotos) do
                local flagStatus = photo:getRawMetadata("flagged")
                
                -- Verificar se a foto está bandeirada
                if flagStatus then
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
                        end
                    end)
                end
            end
            
            -- Pequena pausa para evitar alto consumo de CPU
            LrTasks.sleep(5) -- Checa a cada 5 segundos
        end
    end)
end

monitorFlagging()
