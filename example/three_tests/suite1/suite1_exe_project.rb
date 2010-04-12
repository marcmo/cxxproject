def define_project(config)
  Exe.new(config, 'suite1').
    set_dependencies(['suite1_lib', 'main'])
end
