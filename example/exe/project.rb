def define_project
  res = Exe.new('exe')
  res.dependencies = ['2']
  res.sources = FileList.new('**/*.cpp')
  return res
end
