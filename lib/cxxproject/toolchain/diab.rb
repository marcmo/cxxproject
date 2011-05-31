require 'cxxproject/toolchain/provider'
require 'cxxproject/utils/utils'
require 'cxxproject/errorparser/diab_error_parser'
require 'cxxproject/errorparser/diab_linker_error_parser'

module Cxxproject
  module Toolchain

    diabErrorParser = DiabErrorParser.new
    diabLinkerErrorParser = DiabLinkerErrorParser.new

    DiabChainDebug = Provider.add("Diab_Debug")

    DiabChainDebug[:COMPILER][:C].update({
      :COMMAND => "dcc",
      :FLAGS => "-tPPCE200Z6VEN:simple -O -XO -Xsize-opt -Xsmall-const=0 -Xenum-is-best -Xexceptions-off -g",
      :DEFINE_FLAG => "-D",
      :OBJECT_FILE_FLAG => "-o",
      :INCLUDE_PATH_FLAG => "-I",
      :COMPILE_FLAGS => "-c",
      :DEP_FLAGS => "-Xmake-dependency=6 -Xmake-dependency-savefile=",
      :ERROR_PARSER => diabErrorParser
    })

    DiabChainDebug[:COMPILER][:CPP] = Utils.deep_copy(DiabChainDebug[:COMPILER][:C])
    DiabChainDebug[:COMPILER][:CPP][:FLAGS] = DiabChainDebug[:COMPILER][:CPP][:FLAGS] + " -Xrtti-off"
    DiabChainDebug[:COMPILER][:CPP][:SOURCE_FILE_ENDINGS] = Provider.default[:COMPILER][:CPP][:SOURCE_FILE_ENDINGS]

    DiabChainDebug[:COMPILER][:ASM] = Utils.deep_copy(DiabChainDebug[:COMPILER][:C])
    DiabChainDebug[:COMPILER][:ASM][:COMMAND] = "das"
    DiabChainDebug[:COMPILER][:ASM][:FLAGS] = "-tPPCE200Z6VEN:simple -Xisa-vle -g -Xasm-debug-on"
    DiabChainDebug[:COMPILER][:ASM][:COMPILE_FLAGS] = ""
    DiabChainDebug[:COMPILER][:ASM][:SOURCE_FILE_ENDINGS] = Provider.default[:COMPILER][:ASM][:SOURCE_FILE_ENDINGS]

    DiabChainDebug[:ARCHIVER][:COMMAND] = "dar"
    DiabChainDebug[:ARCHIVER][:ARCHIVE_FLAGS] = "-rc"
    DiabChainDebug[:ARCHIVER][:ERROR_PARSER] = diabErrorParser

    DiabChainDebug[:LINKER][:COMMAND] = "dcc"
    DiabChainDebug[:LINKER][:SCRIPT] = "-Wm"
    DiabChainDebug[:LINKER][:USER_LIB_FLAG] = "-l:"
    DiabChainDebug[:LINKER][:EXE_FLAG] = "-o"
    DiabChainDebug[:LINKER][:LIB_FLAG] = "-l"
    DiabChainDebug[:LINKER][:LIB_PATH_FLAG] = "-L"
    DiabChainDebug[:LINKER][:MAP_FILE_FLAG] = "-Wl,-m6" # no map file if this string is empty, otherwise -Wl,-m6>abc.map
    DiabChainDebug[:LINKER][:FLAGS] = "-ulink_date_time -uResetConfigurationHalfWord -Wl,-Xstop-on-redeclaration -Wl,-Xstop-on-warning -tPPCE200Z6VEN:simple -Wl,-Xremove-unused-sections -Wl,-Xunused-sections-list"
    DiabChainDebug[:LINKER][:OUTPUT_ENDING] = ".elf"
    DiabChainDebug[:LINKER][:ERROR_PARSER] = diabLinkerErrorParser

    DiabChainRelease = Provider.add("Diab_Release", "Diab_Debug")
    DiabChainRelease[:COMPILER][:C][:FLAGS] = "-tPPCE200Z6VEN:simple -XO -Xsize-opt -Xsmall-const=0 -Xenum-is-best -Xsection-split -Xforce-declarations"
    DiabChainRelease[:COMPILER][:CPP][:FLAGS] = "-tPPCE200Z6VEN:simple -XO -Xsize-opt -Xsmall-const=0 -Xenum-is-best -Xrtti-off -Xexceptions-off -Xsection-split"

  end
end
