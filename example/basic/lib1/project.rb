cxx_configuration do
  source_lib "1",
    :sources => FileList['*.cpp'],
    :includes => ['.'],
    :output_dir => 'build'
end
