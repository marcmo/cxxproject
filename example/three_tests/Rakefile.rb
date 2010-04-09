require 'cxxproject'
Compiler = OsxCompiler.new('osx')
CxxProject2Rake.new(Dir.glob('**/project.rb'))
