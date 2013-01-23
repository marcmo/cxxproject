cxx_configuration do
  deps = ['1', BinaryLibrary.new('z')]
  deps << BinaryLibrary.new('dl') if Utils::OS.linux?
  static_lib "2",
    :sources => FileList['**/*.cpp'],
    :dependencies => deps,
    :includes => ['.']
end
