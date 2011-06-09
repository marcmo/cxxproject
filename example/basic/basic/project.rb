cxx_configuration do
  exe "basic",
    :sources => FileList['**/*.cpp'],
    :dependencies => ['2'],
    :output_dir => 'local_build'
  exe "debug",
    :sources => FileList['**/*.cpp'],
    :dependencies => ['2_debug']
end
