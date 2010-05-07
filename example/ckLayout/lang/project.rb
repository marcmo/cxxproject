def define_project()
  files = FileList['**/*.cpp']
  SourceLibrary.new('io').
    set_sources(files)
end
        
