def define_project
  res = Exe.new('exe')
  res.dependencies = ['2']
  res.sources = FileList["**/*.cpp"] # ['main.cpp', 'help.cpp']
  return res
end
