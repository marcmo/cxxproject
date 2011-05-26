cxx_configuration do
  exe "suite2",
  :dependencies => ['suite2_lib', 'main']
  source_lib "suite2_lib",
  :sources => FileList.new('**/*.cpp')
end
