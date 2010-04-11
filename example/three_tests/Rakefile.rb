require 'cxxproject'
BuildDir='build'
CxxProject2Rake.new(Dir.glob('**/*project.rb'),OsxCompiler.new(BuildDir))

desc "run test exes"
task :run do
  exes = Dir.glob("**/*.exe").find_all{|f| File.executable?(f)}
  exes.each do |x|
    sh x
  end
end

