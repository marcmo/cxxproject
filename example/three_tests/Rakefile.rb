require 'cxxproject'
CxxProject2Rake.new(Dir.glob('**/*project.rb'),OsxCompiler.new('build'))

