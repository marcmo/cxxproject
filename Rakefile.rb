require 'rake/clean'
require './rake_helper/spec.rb'

desc "Default Task"
task :default => [:install]


begin
  require 'rubygems/package_task'
  spec = Gem::Specification.load('cxx.gemspec')
  Gem::PackageTask.new(spec){|pkg|}

  desc "install gem globally"
  task :install => [:gem] do
    sh "gem install pkg/#{spec.name}-#{spec.version}.gem"
  end


  begin
    require 'rdoc'
    require 'rdoc/task'
    RDoc::Task.new do |rd|
      rd.rdoc_files.include(spec.files)
    end
  rescue LoadError => e
    task :rdoc do
      puts 'please gem install rdoc'
    end
  end
  begin
    require 'roodi'
    require 'roodi_task'
    class RoodiTask
      def define
        # copied from roodi_task.rb
        desc "Check for design issues in: #{patterns.join(', ')}"
        task name do
          runner = Roodi::Core::Runner.new
          runner.config = config if config
          patterns.each do |pattern|
            Dir.glob(pattern).each { |file| runner.check_file(file) }
          end
          runner.errors.each {|error| puts error}
          # raise "Found #{runner.errors.size} errors." unless runner.errors.empty?
        end
        self
      end
    end
    RoodiTask.new('roodi', spec.files)
    task :gem => [:roodi]
  rescue LoadError # don't bail out when people do not have roodi installed!
      puts 'please gem install roodi'
  end
rescue LoadError => e
    puts "please missing gems #{e}" 
end

def two_digits(x)
  if x.length > 1
    x
  else
    "0#{x}"
  end
end

begin
  require 'grit'
  include Grit

  def git_history      
    repo = Repo.new('.')
    tag_names = repo.tags.collect {|t| t.name }
    relevant_tags = repo.tags.reject {|t| !t.name.start_with?("v_")}
    sorted_tags = relevant_tags.sort_by.each do |t|
      /v_(?<x>\d+)\.(?<y>\d+)\.(?<z>\d+)/ =~ t.name
      "#{two_digits(x)}-#{two_digits(y)}-#{two_digits(z)}"
    end

    change_text = []
    zipped = sorted_tags[0..-2].zip(sorted_tags[1..-1])
    zipped.reverse.each do |a,b|
      change_text << ""
      change_text << "#{a.name} => #{b.name}"
      change_text << ""
      cs = repo.commits_between(a.commit, b.commit)
      cm = cs.each do |c| 
        change_lines = c.message.lines.to_a
        first = change_lines.first
        change_text << "    * " + first + "#{change_lines[1..-1].collect {|l| "      #{l}"}.join("")}"
      end
    end
    change_text
  end
      
  desc 'generate version history'
  task :generate_history do
    puts git_history
  end

  desc 'generate and update version history'
  task :update_version_history do
    change_line = "## Change History:"
    readme = 'README.md'
    content = File.read(readme)
    File.open(readme, 'w') do |f|
      f.puts content.gsub(/^#{change_line}.*/m, ([change_line] << git_history).join("\n"))
    end
  end

rescue LoadError => e
  puts 'to build the version history please gem install grit'
end


require './rake_helper/perftools'

