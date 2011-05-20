require 'rake'

include FileUtils

PKG_VERSION = '0.4.5'
PKG_FILES = FileList[
  'lib/**/*.rb',
  'lib/tools/**/*.template',
  'Rakefile.rb',
  'spec/**/*.rb'
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
  s.author = ''
  s.email = 'oliver.mueller@gmail.com'
  s.homepage = 'https://github.com/marcmo/cxxproject'
  s.add_dependency('highline', '>= 1.6.0')
  s.executables = ["cxx"]
end
