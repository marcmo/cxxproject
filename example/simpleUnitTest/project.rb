def define_project()
  Exe.new('dependency_test').
    set_sources(FileList['**/*.cpp']).
    set_dependencies([BinaryLibrary.new('cppunit')])
end
