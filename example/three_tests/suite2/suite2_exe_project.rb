def define_project(config)
  Exe.new(config, 'suite2').
    set_dependencies(['suite2_lib', 'main'])
end
