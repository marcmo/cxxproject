def define_project()
  SourceLibrary.new('suite2_lib').
    set_sources(FileList.new('**/*.cpp'))
end
