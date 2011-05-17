cxx_configuration "1" do
  source_lib "1",
    :sources => FileList['lib1.cpp'],
    :includes => ['.']
end
