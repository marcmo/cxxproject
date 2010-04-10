def define_project
  res = Exe.new('suite1')
  res.dependencies = ['suite1_lib', 'main']
  return res
end
