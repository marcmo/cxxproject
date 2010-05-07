def define_project()
  SourceLibrary.new('suite1_lib').
    set_sources(FileList.new('**/*.cpp'))
end
