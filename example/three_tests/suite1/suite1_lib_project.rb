def define_project(config)
  SourceLibrary.new(config, 'suite1_lib').
    set_sources(FileList.new('**/*.cpp'))
end
