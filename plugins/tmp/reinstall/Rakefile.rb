require 'rake/clean'

desc 'reinstall plugins'
task :reinstall do
  toolchainpath="../../../plugins/"
  plugins = ["clang"]
  # plugins = ["gcc","clang"]
  plugins.each do |p|
    plugin = "cxxproject_#{p}toolchain"
    sh "gem uninstall #{plugin}" 
    cd "#{toolchainpath}toolchain#{p}" do
      sh "gem build #{p}.gemspec"
      sh "gem install #{plugin}"
    end
  end
end
