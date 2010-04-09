def define_project
  res = SourceLibrary.new('suite1')
  res.dependencies = ['main']
  res.sources = FileList.new('**/*.cpp')
  return res
end
