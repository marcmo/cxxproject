def define_project(config)
  res = Exe.new(config, 'basic')
  res.dependencies = ['2']
  res.sources = FileList.new('**/*.cpp')
  return res
end
