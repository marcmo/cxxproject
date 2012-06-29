cxx_configuration do
  exe "testme",
    :sources => FileList['**/*.cpp'],
    :includes => ['.'],
    :dependencies => []
end
