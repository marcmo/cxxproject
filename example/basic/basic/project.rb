def define_project
  res = Exe.new('basic')
  res.dependencies = ['2']
  res.sources = FileList.new('**/*.cpp')
  return res
end
