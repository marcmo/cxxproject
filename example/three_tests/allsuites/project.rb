def define_project(config)
  res = Exe.new(config, 'allsuites')
  res.dependencies = ['suite1_lib', 'suite2_lib', 'main']
  return res
end
