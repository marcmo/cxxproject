$:.unshift(File.dirname(__FILE__)+"/")

require "rake"
require 'yaml'

include FileUtils

YAML::ENGINE.yamler = 'syck'

PKG_VERSION = "0.1.0"
PKG_FILES = FileList[
  "lib/**/*.rb"
]

Gem::Specification.new do |s|
  s.name = "cxxproject_gcctoolchain"
  s.version = PKG_VERSION
  s.summary = "toolchain support for gcc."
  s.description = <<-EOF
    Toolchain supporting GCC
  EOF
  s.files = PKG_FILES.to_a
  s.require_path = "lib"
  s.author = "oliver mueller"
  s.email = "oliver.mueller@gmail.com"
  s.homepage = "https://github.com/marcmo/cxxproject"
  # s.add_dependency("cxxproject", ">= 0.6.1")
end
