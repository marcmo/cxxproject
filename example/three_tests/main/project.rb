def define_project(config)
  BinaryLibrary.new(config, 'cppunit')
    .set_includes(['/usr/local/include'])
  SourceLibrary.new(config, 'main')
    .set_sources(['main.cpp'])
    .set_dependencies(['cppunit'])
end
