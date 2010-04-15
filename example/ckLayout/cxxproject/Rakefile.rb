require 'cxxproject'
compiler = OsxCompiler.new('build').set_defines(['OSX']).set_includes(['..'])
CxxProject2Rake.new(Dir.glob('../**/*project.rb'), compiler, '../')
