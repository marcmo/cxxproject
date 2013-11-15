# -*- encoding: utf-8 -*-
gem_name = 'cxxproject'
require File.expand_path("lib/#{gem_name}/version")


Gem::Specification.new do |s|
  s.name = gem_name
  s.version = Cxxproject::VERSION
  s.license = 'FreeBSD'

  s.summary = "Cpp Support for Rake."
  s.description = <<-EOF
    Some more high level building blocks for cpp projects.
  EOF
  s.files = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md)
  s.require_path = 'lib'
  s.author = 'oliver mueller'
  s.email = 'oliver.mueller@gmail.com'
  s.homepage = 'https://github.com/marcmo/cxxproject'

  s.add_dependency('colored')
  s.add_dependency('frazzle')
end
