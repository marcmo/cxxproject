def define_project(config)
  e = Exe.new(config, 'dependency_test')
  e.sources = FileList['**/*.cpp']
  e
end
