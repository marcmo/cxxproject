cxx_configuration do
  exe 'main', :sources => ['../../build/gen/test.cpp', '../main.cpp'], :output_dir => 'build'
end
