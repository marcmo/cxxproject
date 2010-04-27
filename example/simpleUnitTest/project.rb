def define_project(config)
  Exe.new(config, 'dependency_test').
    set_sources(FileList['**/*.cpp']).
    set_dependencies([BinaryLibrary.new(config, 'cppunit')])
end
