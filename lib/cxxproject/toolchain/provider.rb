require 'cxxproject/toolchain/colorizing_formatter'

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
            :FLAGS => [],
            :SOURCE_FILE_ENDINGS => [".cxx", ".cpp", ".c++", ".cc", ".C"],
            :DEP_FLAGS => "",
            :DEP_FLAGS_SPACE => false,
            :ERROR_PARSER => nil,
            :PREPRO_FLAGS => ""
          },
          :C => {
            :COMMAND => "",
            :DEFINE_FLAG => "",
            :OBJECT_FILE_FLAG => "",
            :INCLUDE_PATH_FLAG => "",
            :COMPILE_FLAGS => "",
            :DEFINES => [],
            :FLAGS => [],
            :SOURCE_FILE_ENDINGS => [".c"],
            :DEP_FLAGS => "",
            :DEP_FLAGS_SPACE => false,
            :ERROR_PARSER => nil,
            :PREPRO_FLAGS => ""
          },
          :ASM => {
            :COMMAND => "",
            :DEFINE_FLAG => "",
            :OBJECT_FILE_FLAG => "",
            :INCLUDE_PATH_FLAG => "",
            :COMPILE_FLAGS => "",
            :DEFINES => [],
            :FLAGS => [],
            :SOURCE_FILE_ENDINGS => [".asm", ".s", ".S"],
            :DEP_FLAGS => "",
            :ERROR_PARSER => nil,
            :PREPRO_FLAGS => ""
          }
        },

        :ARCHIVER =>
        {
          :COMMAND => "",
          :ARCHIVE_FLAGS => "",
          :FLAGS => [],
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
          :FLAGS => [],
          :MAP_FILE_FLAG => "",
          :OUTPUT_ENDING => ".exe", # or .elf
          :ERROR_PARSER => nil,
          :START_OF_WHOLE_ARCHIVE => '',
          :END_OF_WHOLE_ARCHIVE => ''
        },

        :MAKE =>
        {
          :COMMAND => "make",
          :FLAGS => "-j",
          :FILE_FLAG => "-f",
          :DIR_FLAG => "-C",
          :CLEAN => "clean"
        },

        :CONSOLE_HIGHLIGHTER => ColorizingFormatter.new
      }

      def self.add(name, basedOn = nil)
        chain = Marshal.load(Marshal.dump(basedOn.nil? ? @@default : @@settings[basedOn]))
        @@settings[name] = chain
        chain
      end

      # merge hashB into hashA
      # recurse on sub-hash-structures
      # elements present in hashA only will be taken from hashA
      # elements present in hashB only will be taken from hashB
      # elements present in both will be taken from hashB
      #
      def self.merge(hashA,hashB,overwrite=true)
        missingKeys = hashB.keys - hashA.keys
        missingKeys.each do |k|
          hashA[k] = hashB[k]
        end
        hashA.each do |k,v|
          if v.is_a? Hash
            merge(v,hashB[k],overwrite) if hashB[k]
          else
            hashA[k] = hashB[k] if hashB[k] and overwrite
          end
        end
        hashA
      end

      def self.default
        @@default
      end

      def self.modify_linker(based_on, h)
        chain = @@settings[based_on]
        raise "unknown toolchain: #{based_on}" unless chain
        chain[:LINKER].update(h)
        chain
      end

      def self.modify_compiler(based_on, compiler_type, h)
        chain = @@settings[based_on]
        raise "unknown toolchain: #{based_on}" unless chain
        chain[:COMPILER][compiler_type].update(h)
        chain
      end

      def self.modify_cpp_compiler(based_on, h)
        modify_compiler(based_on, :CPP, h)
      end

      def self.[](name)

        if name == "TI"
          if not ENV['TI_HOME']
            Printer.printError "Error: Please set TI_HOME"
            ExitHelper.exit(1)
          end
        end

        return @@settings[name] if @@settings.include? name
        nil
      end

      def self.list
        return @@settings
      end

    end

  end
end
