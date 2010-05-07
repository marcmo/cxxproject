def define_project()
  Exe.new('suite1').
    set_dependencies(['suite1_lib', 'main'])
end
