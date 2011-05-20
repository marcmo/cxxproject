cxx_configuration do
  exe "basic",
    :sources => FileList['**/*.cpp'],
    :dependencies => ['2']
  exe "debug",
    :sources => FileList['**/*.cpp'],
    :dependencies => ['2_debug']
end
