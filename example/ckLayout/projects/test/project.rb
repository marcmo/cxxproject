cxx_configuration do
  exe "test",
    :sources => FileList.new('**/*.cpp'),
    :dependencies => ['lang', 'io']
end
          
