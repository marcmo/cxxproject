$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'cxxproject/utils/optional'
initialize_simplecov = lambda do
  require 'simplecov'
  if ENV['COVERAGE']
    SimpleCov.start do
      add_group 'buildingblocks', 'lib/cxxproject/buildingblocks'
      add_group 'utils', 'lib/cxxproject/utils'
      add_group 'errorparser', 'lib/cxxproject/errorparser'
      add_group 'toolchain', 'lib/cxxproject/toolchain'
      add_group 'ext', 'lib/cxxproject/ext'
    end
  end
end
Cxxproject::Utils::optional_package(initialize_simplecov, nil)

RakeFileUtils.send(:verbose, false)
