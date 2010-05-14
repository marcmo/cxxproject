cxx_configuration "suite1" do
  exe "suite1",
    :dependencies => ['suite1_lib', 'main']
end
