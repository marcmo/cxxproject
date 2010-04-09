def define_project()
  lib = SourceLibrary.new('2')
  lib.sources = ["lib2.cpp"]
  lib.dependencies = ['1']
  return lib
end
