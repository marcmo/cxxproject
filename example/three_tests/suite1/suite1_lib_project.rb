def define_project
  res = SourceLibrary.new('suite1_lib')
  res.sources = FileList.new('**/*.cpp')
  return res
end
