require 'cxxproject/utils/utils'
require 'cxxproject/toolchain/provider'
require 'cxxproject/errorparser/error_parser'
require 'cxxproject/errorparser/gcc_compiler_error_parser'
require 'cxxproject/errorparser/gcc_linker_error_parser'

module Cxxproject
  module Toolchain
    gccCompilerErrorParser = GCCCompilerErrorParser.new
    gccLinkerErrorParser = GCCLinkerErrorParser.new
      
    GCCChain = Provider.add("GCC")

    GCCChain[:COMPILER][:CPP].update({
      :COMMAND => "g++",
      :DEFINE_FLAG => "-D",
      :OBJECT_FILE_FLAG => "-o",
      :INCLUDE_PATH_FLAG => "-I",
      :COMPILE_FLAGS => "-c ",
      :DEP_FLAGS => "-MMD -MF ", # empty space at the end is important!
      :ERROR_PARSER => gccCompilerErrorParser
    })

    GCCChain[:COMPILER][:C] = Utils.deep_copy(GCCChain[:COMPILER][:CPP])
    GCCChain[:COMPILER][:C][:SOURCE_FILE_ENDINGS] = Provider.default[:COMPILER][:C][:SOURCE_FILE_ENDINGS]
    GCCChain[:COMPILER][:C][:COMMAND] = "gcc"

    GCCChain[:COMPILER][:ASM] = Utils.deep_copy(GCCChain[:COMPILER][:C])
    GCCChain[:COMPILER][:ASM][:SOURCE_FILE_ENDINGS] = Provider.default[:COMPILER][:ASM][:SOURCE_FILE_ENDINGS]

    GCCChain[:ARCHIVER][:COMMAND] = "ar"
    GCCChain[:ARCHIVER][:ARCHIVE_FLAGS] = "-rc"

    GCCChain[:LINKER][:COMMAND] = "g++"
    GCCChain[:LINKER][:SCRIPT] = "-T"
    GCCChain[:LINKER][:USER_LIB_FLAG] = "-l:"
    GCCChain[:LINKER][:EXE_FLAG] = "-o"
    GCCChain[:LINKER][:LIB_FLAG] = "-l"
    GCCChain[:LINKER][:LIB_PATH_FLAG] = "-L"
    GCCChain[:LINKER][:ERROR_PARSER] = gccLinkerErrorParser
  end
end
