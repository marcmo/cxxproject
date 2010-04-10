def define_project
  res = SourceLibrary.new('suite2_lib')
  res.sources = FileList.new('**/*.cpp')
  return res
end
