def define_project
  res = Exe.new('test2')
  res.dependencies = ['suite2']
  return res
end
