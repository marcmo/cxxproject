cxx_configuration do
  if Utils::OS.linux?
    deps = ['1'] + bin_libs(:z, :dl)
  else
    deps = ['1'] + bin_libs(:z)
  end

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
