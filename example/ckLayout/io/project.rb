cxx_configuration do
  source_lib "lang",
    :sources => FileList['**/*.cpp'],
    :includes => [".."]
end
