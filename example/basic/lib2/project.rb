def define_project(config)
  BinaryLibrary.new(config, 'z')
  deps = ['1', 'z']
  if OS.linux?
    BinaryLibrary.new(config, 'dl')
    deps << 'dl'
  end
  SourceLibrary.new(config, '2').
    set_sources(FileList.new.include("**/*.cpp")).
    set_dependencies(deps)
end
