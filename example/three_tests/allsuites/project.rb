cxx_configuration do
  exe "allsuites",
  :dependencies => ['suite1_lib', 'suite2_lib', 'main']
end
