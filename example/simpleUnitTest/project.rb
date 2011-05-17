cxx_configuration do
  exe "dependency_test",
    :sources => FileList['**/*.cpp'],
    :dependencies => [BinaryLibrary.new('cppunit')]
end
