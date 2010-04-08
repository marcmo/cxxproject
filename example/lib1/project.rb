def define_project()
  lib = SourceLibrary.new()
  lib.name = '1'
  lib.sources = ["lib1.cpp"]
  lib.includes = ["."]
  return lib
end
