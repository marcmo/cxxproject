def define_project()
  Exe.new('suite2').
    set_dependencies(['suite2_lib', 'main'])
end
