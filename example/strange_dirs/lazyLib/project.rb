cxx_configuration do
  source_lib "lazy",
    :sources => FileList['../src/*.cpp'],
    :includes => ['.']
end
