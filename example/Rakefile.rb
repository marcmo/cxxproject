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

def run_rakefiles()
  Dir.glob('**/Rakefile.rb').each do |p|
    dir = File.dirname(p)
    if (dir != ".")
      cd(dir,:verbose => false)  do
        yield
      end
    end
  end
end
