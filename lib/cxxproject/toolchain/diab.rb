require 'cxxproject/toolchain/provider'
require 'cxxproject/utils/utils'
require 'cxxproject/errorparser/diab_compiler_error_parser'
require 'cxxproject/errorparser/diab_linker_error_parser'

module Cxxproject
  module Toolchain

    diabCompilerErrorParser = DiabCompilerErrorParser.new
    diabLinkerErrorParser = DiabLinkerErrorParser.new

    DiabChain = Provider.add("Diab")

    DiabChain[:COMPILER][:C].update({
      :COMMAND => "dcc",
      :FLAGS => "",
      :DEFINE_FLAG => "-D",
      :OBJECT_FILE_FLAG => "-o",
      :INCLUDE_PATH_FLAG => "-I",
      :COMPILE_FLAGS => "-c",
      :DEP_FLAGS => "-Xmake-dependency=6 -Xmake-dependency-savefile=",
      :ERROR_PARSER => diabCompilerErrorParser
    })

    DiabChain[:COMPILER][:CPP] = Utils.deep_copy(DiabChain[:COMPILER][:C])
    DiabChain[:COMPILER][:CPP][:SOURCE_FILE_ENDINGS] = Provider.default[:COMPILER][:CPP][:SOURCE_FILE_ENDINGS]

    DiabChain[:COMPILER][:ASM] = Utils.deep_copy(DiabChain[:COMPILER][:C])
    DiabChain[:COMPILER][:ASM][:COMMAND] = "das"
    DiabChain[:COMPILER][:ASM][:COMPILE_FLAGS] = ""
    DiabChain[:COMPILER][:ASM][:SOURCE_FILE_ENDINGS] = Provider.default[:COMPILER][:ASM][:SOURCE_FILE_ENDINGS]

    DiabChain[:ARCHIVER][:COMMAND] = "dar"
    DiabChain[:ARCHIVER][:ARCHIVE_FLAGS] = "-rc"
    DiabChain[:ARCHIVER][:ERROR_PARSER] = diabCompilerErrorParser

    DiabChain[:LINKER][:COMMAND] = "dcc"
    DiabChain[:LINKER][:SCRIPT] = "-Wm"
    DiabChain[:LINKER][:USER_LIB_FLAG] = "-l:"
    DiabChain[:LINKER][:EXE_FLAG] = "-o"
    DiabChain[:LINKER][:LIB_FLAG] = "-l"
    DiabChain[:LINKER][:LIB_PATH_FLAG] = "-L"
    DiabChain[:LINKER][:MAP_FILE_FLAG] = "-Wl,-m6" # no map file if this string is empty, otherwise -Wl,-m6>abc.map
    DiabChain[:LINKER][:OUTPUT_ENDING] = ".elf"
    DiabChain[:LINKER][:ERROR_PARSER] = diabLinkerErrorParser
    
  end
end
