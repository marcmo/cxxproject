def define_project
  res = SourceLibrary.new('suite2')
  res.dependencies = ['main']
  res.sources = FileList.new('**/*.cpp')
  return res
end
