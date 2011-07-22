require 'rake'

include FileUtils

PKG_VERSION = '0.5.6'
PKG_FILES = FileList[
  'lib/**/*.rb',
  'Rakefile.rb',
  'spec/**/*.rb',
  'lib/tools/**/*.template'
]

Gem::Specification.new do |s|
  s.name = 'cxxproject'
  s.version = PKG_VERSION
  s.summary = "Cpp Support for Rake."
  s.description = <<-EOF
    Some more high level building blocks for cpp projects.
  EOF
  s.files = PKG_FILES.to_a
  s.require_path = 'lib'
  s.author = 'oliver mueller'
  s.email = 'oliver.mueller@gmail.com'
  s.homepage = 'https://github.com/marcmo/cxxproject'
  s.add_dependency('highline', '>= 1.6.0')
  s.add_dependency('colored')
  s.add_dependency('progressbar')
  s.executables = ['cxx']
end
