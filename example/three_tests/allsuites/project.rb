def define_project(config)
  Exe.new(config, 'allsuites')
    .set_dependencies(['suite1_lib', 'suite2_lib', 'main'])
end
