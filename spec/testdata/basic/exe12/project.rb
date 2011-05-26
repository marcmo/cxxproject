cxx_configuration do
  exe "basic",
    :sources => FileList.new('**/*.cpp'),
    :dependencies => ['2']
end
