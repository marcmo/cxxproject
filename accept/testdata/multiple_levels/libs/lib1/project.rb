cxx_configuration do
  static_lib "1",
    :sources => FileList['lib1.cpp'],
    :includes => ['.']
end
