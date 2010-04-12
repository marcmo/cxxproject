def define_project(config)
  res = SourceLibrary.new(config, 'suite1_lib')
  res.sources = FileList.new('**/*.cpp')
  return res
end
