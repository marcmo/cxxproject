def define_project
  res = Exe.new('test3')
  res.dependencies = ['suite1', 'suite2']
  return res
end
