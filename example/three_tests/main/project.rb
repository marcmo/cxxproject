def define_project()
  cppunit = BinaryLibrary.new('cppunit')
  cppunit.includes = ['/usr/local/include']
  lib = SourceLibrary.new('main')
  lib.sources = ['main.cpp']
  lib.dependencies = ['cppunit']
  return lib
end
