def define_project(config)
  deps = ['1',BinaryLibrary.new(config, 'z')]
  if OS.linux?
    deps << BinaryLibrary.new(config, 'dl')
  end
  SourceLibrary.new(config, '2').
    set_sources(FileList.new.include("**/*.cpp")).
    set_dependencies(deps)
end
