require 'cxxproject'
CxxProject2Rake.new(FileList['**/*project.rb'], "build", GCCChain, '..')
