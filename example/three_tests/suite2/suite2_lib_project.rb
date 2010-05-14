cxx_configuration "suite2_lib" do
  source_lib "suite2_lib",
    :sources => FileList.new('**/*.cpp')
end
