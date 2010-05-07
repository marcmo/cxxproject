def define_project()
  Exe.new('test').
    set_sources(FileList.new('**/*.cpp')).
    set_dependencies(['lang', 'io'])
end
          
