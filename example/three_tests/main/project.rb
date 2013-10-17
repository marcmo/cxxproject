cxx_configuration do
  static_lib "main",
    :sources => ['main.cpp'],
    :dependencies => [BinaryLibrary.new('cppunit')]
end
