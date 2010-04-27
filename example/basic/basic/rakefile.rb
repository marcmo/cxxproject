require 'cxxproject'

cxx_configuration "Test" do
  exe "basic",
    :source => FileList.new('**/*.cpp')
end

