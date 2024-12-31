-- KeywordExportFilter.lua

local LrTasks = import "LrTasks"
local LrApplication = import "LrApplication"
local LrLogger = import "LrLogger"

local myLogger = LrLogger("CompradoFilterLogger")
myLogger:enable("print")

local ExportFilter = {}

function ExportFilter.sectionsForTopOfDialog(f, propertyTable)
    return {
        {
            title = "Adicionar Keyword 'Comprado'",
            synopsis = "Marca fotos bandeiradas com a keyword 'comprado'",
            f:static_text {
                title = "Este plugin adiciona 'comprado' a fotos bandeiradas ao exportar.",
            },
        },
    }
end

function ExportFilter.postProcessRenderedPhotos(functionContext, exportContext)
    local exportSession = exportContext.exportSession
    local photosToExport = exportSession:photosToExport()
    local catalog = LrApplication.activeCatalog()

    local compradoKeyword
    catalog:withWriteAccessDo("CriarKeywordComprado", function()
        compradoKeyword = catalog:createKeyword("comprado", {}, true, nil)
    end)

    for _, rendition in ipairs(photosToExport) do
        local photo = rendition.photo
        local flagStatus = photo:getRawMetadata("pickStatus")
        if flagStatus == 1 then
            catalog:withWriteAccessDo("AdicionarKeywordNaFoto", function()
                photo:addKeyword(compradoKeyword)
                myLogger:trace("Keyword 'comprado' adicionada à foto bandeirada.")
            end)
        end
    end
end

return ExportFilter
