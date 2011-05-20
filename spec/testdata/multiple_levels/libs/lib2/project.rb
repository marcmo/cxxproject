cxx_configuration do
  deps = ['1', BinaryLibrary.new('z')]
  deps << BinaryLibrary.new('dl') if OS.linux?

  source_lib "2",
    :sources => FileList['**/*.cpp'],
    :dependencies => deps,
    :includes => ['.']


  unittest_flags = {
    :DEFINES => ['UNIT_TEST','CPPUNIT_MAIN="main"']
  }
  source_lib "2_debug",
    :sources => FileList['**/*.cpp'],
    :dependencies => deps,
    :includes => ['.'],
    :toolchain => Provider.modify_cpp_compiler("GCC", unittest_flags)
end
