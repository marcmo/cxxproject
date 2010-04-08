def define_project
  res = Exe.new
  res.name = 'exe'
  res.libs = ['2']
  res.sources = ['main.cpp', 'help.cpp']
  return res
end
