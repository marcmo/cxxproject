def define_project()
  SourceLibrary.new('main').
    set_sources(['main.cpp']).
    set_dependencies([BinaryLibrary.new('cppunit')])
end
