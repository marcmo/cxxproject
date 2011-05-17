cxx_configuration "basic" do
  exe "basic",
    :sources => FileList['**/*.cpp'],
    :dependencies => ['2']
end
