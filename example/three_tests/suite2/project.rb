cxx_configuration do
  exe "suite2",
    :dependencies => ['suite2_lib', 'main']
  static_lib "suite2_lib",
    :sources => FileList.new('**/*.cpp')
end
