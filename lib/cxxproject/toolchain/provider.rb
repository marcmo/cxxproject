module Cxxproject
  module Toolchain

    class Provider
      @@settings = {}
      @@default = {
        :COMPILER =>
        {
          :CPP => {
            :COMMAND => "",
            :DEFINE_FLAG => "",
            :OBJECT_FILE_FLAG => "",
            :INCLUDE_PATH_FLAG => "",
            :COMPILE_FLAGS => "",
            :DEFINES => [],
            :FLAGS => "",
            :SOURCE_FILE_ENDINGS => [".cxx", ".cpp", ".c++", ".cc", ".C"],
            :DEP_FLAGS => "",
            :ERROR_PARSER => nil
          },
          :C => {
            :COMMAND => "",
            :DEFINE_FLAG => "",
            :OBJECT_FILE_FLAG => "",
            :INCLUDE_PATH_FLAG => "",
            :COMPILE_FLAGS => "",
            :DEFINES => [],
            :FLAGS => "",
            :SOURCE_FILE_ENDINGS => [".c"],
            :DEP_FLAGS => "",
            :ERROR_PARSER => nil
          },
          :ASM => {
            :COMMAND => "",
            :DEFINE_FLAG => "",
            :OBJECT_FILE_FLAG => "",
            :INCLUDE_PATH_FLAG => "",
            :COMPILE_FLAGS => "",
            :DEFINES => [],
            :FLAGS => "",
            :SOURCE_FILE_ENDINGS => [".asm", ".s", ".S"],
            :DEP_FLAGS => "",
            :ERROR_PARSER => nil
          }
        },

        :ARCHIVER =>
        {
          :COMMAND => "",
          :ARCHIVE_FLAGS => "",
          :FLAGS => "",
          :ERROR_PARSER => nil
        },

        :LINKER =>
        {
          :COMMAND => "",
          :MUST_FLAGS => "",
          :SCRIPT => "",
          :USER_LIB_FLAG => "",
          :EXE_FLAG => "",
          :LIB_FLAG => "",
          :LIB_PATH_FLAG => "",
          :LIB_PREFIX_FLAGS => "", # "-Wl,--whole-archive",
          :LIB_POSTFIX_FLAGS => "", # "-Wl,--no-whole-archive",
          :FLAGS => "",
          :MAP_FILE_FLAG => "",
          :OUTPUT_ENDING => ".exe", # or .elf
          :ERROR_PARSER => nil
        },

        :MAKE =>
        {
          :COMMAND => "make",
          :MAKE_FLAGS => "",
          :FLAGS => "-j",
          :FILE_FLAG => "-f",
          :DIR_FLAG => "-C",
          :CLEAN => "clean"
        },

      }

      def self.add(name, basedOn = nil)
        chain = Marshal.load(Marshal.dump(basedOn.nil? ? @@default : @@settings[basedOn]))
        @@settings[name] = chain
        chain
      end

      def self.default
        @@default
      end

      def self.modify_cpp_compiler(based_on, h)
        chain = Marshal.load(Marshal.dump(@@settings[based_on]))
        chain[:COMPILER][:CPP].update(h)
        chain
      end

      def self.[](name)
        return @@settings[name] if @@settings.include? name
        nil
      end

    end

  end
end

require 'cxxproject/toolchain/diab'
require 'cxxproject/toolchain/gcc'
require 'cxxproject/toolchain/clang'

