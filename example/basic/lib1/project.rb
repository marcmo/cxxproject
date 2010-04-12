def define_project(config)
  lib = SourceLibrary.new(config, '1')
  lib.sources = ['lib1.cpp']
  return lib
end
