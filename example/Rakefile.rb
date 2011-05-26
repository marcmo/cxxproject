desc 'clean examples'
task :clean do
  run_rakefiles{ sh "rake clobber" }
end

desc 'build examples'
task :all do
  run_rakefiles { sh "rake" }
end

desc "run executables"
task :execute => [:all] do
  Dir['**/*.exe'].each do |f|
    sh f do |ok, res|
      puts "#{f} => #{ok}"
    end
  end
end

task :default => :execute

Testprojects = [
  'basic',
  # 'ckLayout', => needs to be fixed
  'dependency_tests',
  'simpleUnitTest',
'three_tests']
def run_rakefiles()
  Testprojects.each do |p|
    cd p do
      dir = File.dirname('Rakefile.rb')
      yield
    end
  end
end
