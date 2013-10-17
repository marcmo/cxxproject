require 'rake/clean'
require './rake_helper/spec.rb'

desc "Default Task"
task :default => [:install]


begin
  require 'rubygems/package_task'
  spec = Gem::Specification.load('cxxproject.gemspec')
  Gem::PackageTask.new(spec){|pkg|}

  desc "install gem globally"
  task :install => [:gem] do
    sh "gem install pkg/#{spec.name}-#{spec.version}.gem"
  end

  desc "deploy gem to rubygems"
  task :deploy => :gem do
    require 'highline/import'
    new_gem = "pkg/#{spec.name}-#{spec.version}.gem"
    say "This will deploy #{new_gem} to rubygems server"
    if agree("Are you sure you want to continue? [y/n]") then
      sh "gem push #{new_gem}"
    end
  end

  begin
    require 'rdoc'
    require 'rdoc/rdoctask'
    RDoc::Task.new do |rd|
      rd.rdoc_files.include(spec.files)
    end
  rescue LoadError => e
    task :rdoc do
      puts 'please gem install rdoc'
    end
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

  VERSION_REGEXP = Regexp.new("v?_?(?<x>\\d+)\\.(?<y>\\d+)\.(?<z>\\d+)")
  def git_history
    repo = Repo.new('.')

    relevant_tags = repo.tags.select {|t| VERSION_REGEXP.match(t.name) }
    sorted_tags = relevant_tags.sort_by.each do |t|
      match = VERSION_REGEXP.match(t.name)
      "#{two_digits(match[:x])}-#{two_digits(match[:y])}-#{two_digits(match[:z])}"
    end

    change_text = []
    zipped = sorted_tags[0..-2].zip(sorted_tags[1..-1])
    zipped.reverse.each do |a,b|
      change_text << ""
      change_text << "#{a.name} => #{b.name}"
      change_text << ""
      cs = repo.commits_between(a.commit, b.commit).each do |c|
        change_lines = c.message.lines.to_a.delete_if {|x|x.index('Change-Id') || x.strip.size==0}
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

