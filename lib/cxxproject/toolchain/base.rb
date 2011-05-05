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
<<<<<<< HEAD
            :SOURCE_FILE_ENDINGS => [".cxx", ".cpp", ".c++", ".cc", ".C"]
=======
            :SOURCE_FILE_ENDINGS => [".cxx", ".cpp", ".c++", ".cc", ".C"],
            :DEP_FLAGS => ""
>>>>>>> apichange
          },
          :C => {
            :COMMAND => "",
            :DEFINE_FLAG => "",
            :OBJECT_FILE_FLAG => "",
            :INCLUDE_PATH_FLAG => "",
            :COMPILE_FLAGS => "",
            :DEFINES => [],
            :FLAGS => "",
<<<<<<< HEAD
            :SOURCE_FILE_ENDINGS => [".c"]
=======
            :SOURCE_FILE_ENDINGS => [".c"],
            :DEP_FLAGS => ""
>>>>>>> apichange
          },
          :ASM => {
            :COMMAND => "",
            :DEFINE_FLAG => "",
            :OBJECT_FILE_FLAG => "",
            :INCLUDE_PATH_FLAG => "",
            :COMPILE_FLAGS => "",
            :DEFINES => [],
            :FLAGS => "",
<<<<<<< HEAD
            :SOURCE_FILE_ENDINGS => [".asm", ".s", ".S"]
=======
            :SOURCE_FILE_ENDINGS => [".asm", ".s", ".S"],
            :DEP_FLAGS => ""
>>>>>>> apichange
          }
        },

        :ARCHIVER =>
        {
          :COMMAND => "",
          :ARCHIVE_FLAGS => "",
          :FLAGS => ""
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


<<<<<<< HEAD
        :DEPENDENCY =>
        {
          :COMMAND => "",
          :FLAGS => ""
        }

      }

      def self.add(name)
        chain = Marshal.load(Marshal.dump(@@default))
        @@settings[name] = chain
        chain
      end
=======
      }

      def self.add(name, basedOn = nil)
        chain = Marshal.load(Marshal.dump(basedOn.nil? ? @@default : @@settings[basedOn]))
        @@settings[name] = chain
        chain
      end

      def self.default
        @@default
      end

>>>>>>> apichange
    end

  end
end
