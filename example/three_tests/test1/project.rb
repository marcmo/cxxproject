def define_project
  res = Exe.new('test1')
  res.dependencies = ['suite1']
  return res
end
