def define_project(config)
  files = FileList['**/*.cpp']
  SourceLibrary.new(config, 'io').
    set_sources(files)
end
        