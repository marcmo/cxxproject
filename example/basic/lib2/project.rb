def define_project(config)
  BinaryLibrary.new(config, 'z')
  lib = SourceLibrary.new(config, '2')
  lib.sources = FileList.new.include("**/*.cpp")
  lib.dependencies = ['1','z']
  if OS.linux?
    p 'adding linux dynamic linker lib'
    BinaryLibrary.new('dl')
    lib.dependencies << 'dl'
  end
  return lib
end
