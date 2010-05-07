def define_project()
  SourceLibrary.new('lang').
    set_sources(FileList['**/*.cpp'])
end
