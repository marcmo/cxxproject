cxx_configuration do
  exe "suite1",
  :dependencies => ['suite1_lib', 'main']
  source_lib "suite1_lib",
  :sources => FileList.new('**/*.cpp')
end
