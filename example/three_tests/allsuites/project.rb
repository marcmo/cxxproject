cxx_configuration "allsuites" do
  exe "allsuites",
    :dependencies => ['suite1_lib', 'suite2_lib', 'main']
end
