def define_project(config)
  SourceLibrary.new(config, 'suite2_lib')
    .set_sources(FileList.new('**/*.cpp'))
end
