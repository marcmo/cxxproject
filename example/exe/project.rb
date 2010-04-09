def define_project
  res = Exe.new('exe')
  res.dependencies = ['2']
  res.sources = ['main.cpp', 'help.cpp']
  return res
end
