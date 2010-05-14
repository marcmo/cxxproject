cxx_configuration "2" do
  deps = ['1', BinaryLibrary.new('z')]
  deps << BinaryLibrary.new('dl') if OS.linux?
  source_lib "2",
    :sources => FileList['**/*.cpp'],
    :dependencies => deps,
    :includes => ['.']
end
