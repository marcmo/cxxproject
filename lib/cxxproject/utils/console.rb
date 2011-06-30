desc 'start a rake console'
task :console do
  require 'irb'
  ARGV.clear
  IRB.start
end
