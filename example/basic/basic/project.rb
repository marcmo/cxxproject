def define_project()
  Exe.new('basic').
    set_sources(FileList.new('**/*.cpp')).
    set_dependencies(['2'])
end
