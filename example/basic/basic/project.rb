cxx_configuration "basic" do
  exe "basic",
    :sources => FileList.new('**/*.cpp'),
    :dependencies => ['2']
end
