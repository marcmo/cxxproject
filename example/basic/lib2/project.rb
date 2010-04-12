def define_project(config)
  BinaryLibrary.new(config, 'z')
  deps = ['1', 'z']
  if OS.linux?
    deps << 'dl'
  end
  SourceLibrary.new(config, '2')
    .set_sources(FileList.new.include("**/*.cpp"))
    .set_dependencies(deps)
end
