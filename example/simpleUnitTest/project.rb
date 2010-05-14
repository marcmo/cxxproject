cxx_configuration "dependency_test" do
  exe "dependency_test",
    :sources => FileList['**/*.cpp'],
    :dependencies => [BinaryLibrary.new('cppunit')]
end
