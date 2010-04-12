def define_project(config)
  SourceLibrary.new(config, 'main').
    set_sources(['main.cpp']).
    set_dependencies([BinaryLibrary.new(config, 'cppunit')])
end
