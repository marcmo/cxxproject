cxx_configuration do
  source_lib "main",
  :sources => ['main.cpp'],
  :dependencies => [BinaryLibrary.new('cppunit')]
end
