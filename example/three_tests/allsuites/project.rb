def define_project
  res = Exe.new('allsuites')
  res.dependencies = ['suite1_lib', 'suite2_lib', 'main']
  return res
end
