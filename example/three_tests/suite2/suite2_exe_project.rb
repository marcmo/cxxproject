def define_project(config)
  res = Exe.new(config, 'suite2')
  res.dependencies = ['suite2_lib', 'main']
  return res
end
