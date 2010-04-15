def define_project(config)
  Exe.new(config, 'test').
    set_sources(FileList.new('**/*.cpp')).
    set_dependencies(['lang', 'io'])
end
          