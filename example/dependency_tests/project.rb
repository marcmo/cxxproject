def define_project(config)
  Exe.new(config, 'dependency_test').
    set_sources(FileList['**/*.cpp'])
end
