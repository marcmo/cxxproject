cxx_configuration do
  exe "suite1",
    :dependencies => ['suite1_lib', 'main']
  static_lib "suite1_lib",
    :sources => FileList.new('**/*.cpp')
end
