def define_project()
  SourceLibrary.new('1').
    set_sources(['lib1.cpp']).set_includes(['.'])
end
