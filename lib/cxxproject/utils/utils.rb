module Cxxproject
  module Utils
    # Simple helper query the operating system we are running in
    module OS

      def self.os
        return :OSX if mac?
        return :LINUX if linux?
        return :WINDOWS if windows?
        return :OTHER
      end

      # Is it windows
      def self.windows?
        (RUBY_PLATFORM =~ /cygwin|mswin|mingw|bccwin|wince|emx/) != nil
      end

      # Is it osx
      def self.mac?
        (RUBY_PLATFORM =~ /darwin/) != nil
      end

      # Is it kind of unix
      def self.unix?
        !OS.windows?
      end

      # Is it linux
      def self.linux?
        OS.unix? and not OS.mac?
      end

    end

    def self.deep_copy(x)
      Marshal.load(Marshal.dump(x))
    end

    def self.old_ruby?
      RUBY_VERSION[0..2] == "1.8"
    end

  end
end
