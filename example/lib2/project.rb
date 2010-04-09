def define_project()
  lib = SourceLibrary.new()
  lib.name = '2'
  lib.sources = ["lib2.cpp"]
  lib.dependencies = ['1']
  return lib
end
