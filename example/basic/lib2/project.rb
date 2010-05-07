def define_project()
  deps = ['1', BinaryLibrary.new('z')]
  deps << BinaryLibrary.new('dl') if OS.linux?
  SourceLibrary.new('2').
    set_sources(FileList['**/*.cpp']).
    set_dependencies(deps).
    set_includes(['.'])
end
