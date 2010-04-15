def define_project(config)
  SourceLibrary.new(config, 'lang').
    set_sources(FileList['**/*.cpp'])
end
