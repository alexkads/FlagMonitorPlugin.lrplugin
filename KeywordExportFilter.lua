-- KeywordExportFilter.lua
local LrTasks       = import "LrTasks"
local LrApplication = import "LrApplication"
local LrLogger      = import "LrLogger"

-- Cria um logger para debug se quiser
local myLogger = LrLogger("CompradoFilterLogger")
myLogger:enable("print")  -- ou "logfile" para logar num arquivo

local ExportFilter = {}

--------------------------------------------------------------------------------
-- 1. Opções que aparecem na tela de exportação, se você quiser customizar
--------------------------------------------------------------------------------
function ExportFilter.sectionsForTopOfDialog(f, propertyTable)
    return {
        {
            id = "AdicionarKeywordComprado",
            title = "Adicionar Keyword 'Comprado'",
            synopsis = "Marca fotos bandeiradas com a keyword 'comprado'",
            f:static_text {
                title = "Este plugin adiciona 'comprado' a fotos bandeiradas ao exportar.",
            },
        },
    }
end

--------------------------------------------------------------------------------
-- 2. Lógica principal de adicionar a keyword
--------------------------------------------------------------------------------
function ExportFilter.postProcessRenderedPhotos(functionContext, exportContext)
    -- Obtém as fotos que estão no batch de exportação
    local exportSession = exportContext.exportSession
    local photosToExport = exportSession:photosToExport()

    -- Obtém referência ao catálogo atual (para poder escrever metadados)
    local catalog = LrApplication.activeCatalog()

    -- Para evitar criar a keyword toda vez, criamos / pegamos apenas uma vez
    local compradoKeyword
    catalog:withWriteAccessDo("CriarKeywordComprado", function()
        -- Cria a keyword se não existir. Se já existir, o LR retorna a mesma
        compradoKeyword = catalog:createKeyword("comprado", {}, true, nil)
    end)

    -- Para cada foto que está sendo exportada, se estiver bandeirada, adiciona a keyword
    for _, rendition in ipairs(photosToExport) do
        local photo = rendition.photo  -- referência à foto no catálogo

        -- photo:getFlag() retorna:
        --    1 => bandeirada
        --    0 => sem bandeira
        --   -1 => rejeitada
        --local flagStatus = photo:getFlag()
        local flagStatus = photo:getRawMetadata("pickStatus")
        if flagStatus == 1 then
            -- Precisamos de acesso de escrita pra alterar keywords da foto
            catalog:withWriteAccessDo("AdicionandoKeywordNaFoto", function()
                photo:addKeyword(compradoKeyword)
                myLogger:trace("Adicionada keyword 'comprado' na foto com bandeira.")
            end)
        end
    end
end

return ExportFilter