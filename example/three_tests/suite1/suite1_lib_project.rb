cxx_configuration "suite1_lib" do
  source_lib "suite1_lib",
    :sources => FileList.new('**/*.cpp')
end
