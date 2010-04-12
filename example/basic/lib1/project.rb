def define_project(config)
  SourceLibrary.new(config, '1').
    set_sources(['lib1.cpp'])
end
