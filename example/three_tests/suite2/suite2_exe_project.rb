def define_project
  res = Exe.new('suite2')
  res.dependencies = ['suite2_lib', 'main']
  return res
end
