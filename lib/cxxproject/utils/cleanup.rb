require 'rake'
require 'rake/clean'
require 'cxxproject/ext/filelist'

module Cxxproject
  module Utils

    def self.cleanup_rake()
      ALL_BUILDING_BLOCKS.clear
      Rake.application.clear
      Rake.application.idei.set_abort(false)
      CLEAN.pending_add.clear
      CLEAN.items.clear
      task :clean do
        CLEAN.each { |fn| rm_r fn rescue nil }
      end
      task :clobber => [:clean] do
        CLOBBER.each { |fn| rm_r fn rescue nil }
      end      
    end

  end
end
