return {
  LrSdkVersion = 10.0,
  LrToolkitIdentifier = 'com.alexkads.flagmonitor',
  LrPluginName = "Flag Monitor Plugin",
  LrForceInitPlugin = true,
  LrInitPlugin = 'Init.lua',
    -- Aqui indicamos ao Lightroom que este plugin fornece um Export Filter
  LrExportFilterProvider = {
    {
        title = "Adicionar Keyword 'Comprado'",
        file = "KeywordExportFilter.lua",  -- Nome do arquivo que contém o filtro
    },
  },
  LrLibraryMenuItems = {
    {
        title = "Monitorar Bandeiramento",
        file = "PhotoObserver.lua",
    }
},
  VERSION = { major = 1, minor = 0, revision = 36 }
}