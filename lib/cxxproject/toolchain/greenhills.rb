require 'cxxproject/toolchain/provider'
require 'cxxproject/utils/utils'
require 'cxxproject/errorparser/greenhills_compiler_error_parser'
require 'cxxproject/errorparser/greenhills_linker_error_parser'

module Cxxproject
  module Toolchain

    GreenHillsChain = Provider.add("GreenHills")

    GreenHillsChain[:COMPILER][:C].update({
      :COMMAND => "ccppc",
      :FLAGS => "",
      :DEFINE_FLAG => "-D",
      :OBJECT_FILE_FLAG => "-o ",
      :INCLUDE_PATH_FLAG => "-I",
      :COMPILE_FLAGS => "-c",
      :DEP_FLAGS => "-Xmake-dependency=6 -Xmake-dependency-savefile=", # -MMD ok, -MF missing?
      :DEP_FLAGS_SPACE => false,
      :PREPRO_FLAGS => "-P" # -E (stdout, oder -o ...)? wahrscheinlich aber -P
    })

    GreenHillsChain[:COMPILER][:CPP] = Utils.deep_copy(GreenHillsChain[:COMPILER][:C])
    GreenHillsChain[:COMPILER][:CPP][:SOURCE_FILE_ENDINGS] = Provider.default[:COMPILER][:CPP][:SOURCE_FILE_ENDINGS]

    GreenHillsChain[:COMPILER][:ASM] = Utils.deep_copy(GreenHillsChain[:COMPILER][:C])
    GreenHillsChain[:COMPILER][:ASM][:COMMAND] = "asppc" # ??
    GreenHillsChain[:COMPILER][:ASM][:COMPILE_FLAGS] = ""
    GreenHillsChain[:COMPILER][:ASM][:SOURCE_FILE_ENDINGS] = Provider.default[:COMPILER][:ASM][:SOURCE_FILE_ENDINGS]
    GreenHillsChain[:COMPILER][:ASM][:PREPRO_FLAGS] = ""

    GreenHillsChain[:ARCHIVER][:COMMAND] = "ccppc" # ??
    GreenHillsChain[:ARCHIVER][:ARCHIVE_FLAGS] = "-rc" # -archive ??

    GreenHillsChain[:LINKER][:COMMAND] = "ccppc" # ??
    GreenHillsChain[:LINKER][:SCRIPT] = "-Wm" # -T file.ld , evtl. -Wl,-T file.ld ???
    GreenHillsChain[:LINKER][:USER_LIB_FLAG] = "-l:" # ?? does that exist ? 
    GreenHillsChain[:LINKER][:EXE_FLAG] = "-o"
    GreenHillsChain[:LINKER][:LIB_FLAG] = "-l"
    GreenHillsChain[:LINKER][:LIB_PATH_FLAG] = "-L"
    GreenHillsChain[:LINKER][:MAP_FILE_FLAG] = "-Wl,-m6" # -map=filename  /  -nomap (default) 
    GreenHillsChain[:LINKER][:OUTPUT_ENDING] = ".elf"

    GreenHillsCompilerErrorParser =                   GreenHillsCompilerErrorParser.new
    GreenHillsChain[:COMPILER][:C][:ERROR_PARSER] =   GreenHillsCompilerErrorParser
    GreenHillsChain[:COMPILER][:CPP][:ERROR_PARSER] = GreenHillsCompilerErrorParser
    GreenHillsChain[:COMPILER][:ASM][:ERROR_PARSER] = GreenHillsCompilerErrorParser
    GreenHillsChain[:ARCHIVER][:ERROR_PARSER] =       GreenHillsCompilerErrorParser
    GreenHillsChain[:LINKER][:ERROR_PARSER] =         GreenHillsLinkerErrorParser.new

  end
end
