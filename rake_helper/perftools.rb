begin
  require 'perftools'
  namespace :perftools do
    def my_cd
      cd('example/big_project', :verbose => false) do
        yield
      end
    end
    task :clean_big_project do
      my_cd do
        require 'fileutils'
        FileUtils.rm_rf('build')
        FileUtils.rm_rf('gen')
      end
    end
    task :generate_big_project => [:clean_big_project] do
      my_cd do
        sh 'rake -f Rakefile_generator.rb'
      end
    end
    task :big_project => [:generate_big_project] do
      my_cd do
        sh 'CPUPROFILE=./test.profile RUBYOPT="-r`gem which perftools | tail -1`" ruby gen/Rakefile.rb'
      end
    end
    desc 'Show perftools profile'
    task :show_profile => [:big_project] do
      my_cd do
        sh 'pprof.rb --web profile'
      end
    end
  end
rescue LoadError => e
end
