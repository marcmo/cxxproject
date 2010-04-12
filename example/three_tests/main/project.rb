def define_project(config)
  cppunit = BinaryLibrary.new(config, 'cppunit')
  cppunit.includes = ['/usr/local/include']
  lib = SourceLibrary.new(config, 'main')
  lib.sources = ['main.cpp']
  lib.dependencies = ['cppunit']
  return lib
end
