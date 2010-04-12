def define_project(config)
  res = Exe.new(config, 'suite1')
  res.dependencies = ['suite1_lib', 'main']
  return res
end
