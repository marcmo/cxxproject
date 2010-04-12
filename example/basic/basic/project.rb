def define_project(config)
  Exe.new(config, 'basic').
    set_sources(FileList.new('**/*.cpp')).
    set_dependencies(['2'])
end
