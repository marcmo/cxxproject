def define_project()
  BinaryLibrary.new('z')
  lib = SourceLibrary.new('2')
  lib.sources = FileList.new.include("**/*.cpp")
  lib.dependencies = ['1', 'z']
  return lib
end
