cxx_configuration "dependency_test" do
  exe 'dependency_test',
    :sources => FileList['**/*.cpp']
end
