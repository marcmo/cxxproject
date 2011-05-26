cxx_configuration "test" do
  exe "test",
    :sources => FileList.new('**/*.cpp'),
    :dependencies => ['lang', 'io']
end
          
