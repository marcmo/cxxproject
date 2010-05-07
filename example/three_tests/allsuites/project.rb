def define_project()
  Exe.new('allsuites').
    set_dependencies(['suite1_lib', 'suite2_lib', 'main'])
end
