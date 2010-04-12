def define_project
  e = Exe.new('dependency_test')
  e.sources = FileList['**/*.cpp']
  e
end
