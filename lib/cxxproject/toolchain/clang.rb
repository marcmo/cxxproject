require 'cxxproject/utils/utils'
require 'cxxproject/toolchain/provider'
require 'cxxproject/errorparser/error_parser'
require 'cxxproject/errorparser/gcc_compiler_error_parser'

module Cxxproject
  module Toolchain
    gccCompilerErrorParser = GCCCompilerErrorParser.new

    CLANG_CHAIN = Provider.add("CLANG")

    CLANG_CHAIN[:COMPILER][:CPP].update({
      :COMMAND => "llvm-g++",
      :DEFINE_FLAG => "-D",
      :OBJECT_FILE_FLAG => "-o",
      :INCLUDE_PATH_FLAG => "-I",
      :COMPILE_FLAGS => "-c ",
      :DEP_FLAGS => "-MD -MF ", # empty space at the end is important!
      :ERROR_PARSER => gccCompilerErrorParser
    })

    CLANG_CHAIN[:COMPILER][:C] = Utils.deep_copy(CLANG_CHAIN[:COMPILER][:CPP])
    CLANG_CHAIN[:COMPILER][:C][:SOURCE_FILE_ENDINGS] = Provider.default[:COMPILER][:C][:SOURCE_FILE_ENDINGS]
    CLANG_CHAIN[:COMPILER][:C][:COMMAND] = "llvm-gcc"

    CLANG_CHAIN[:COMPILER][:ASM] = Utils.deep_copy(CLANG_CHAIN[:COMPILER][:C])
    CLANG_CHAIN[:COMPILER][:ASM][:SOURCE_FILE_ENDINGS] = Provider.default[:COMPILER][:ASM][:SOURCE_FILE_ENDINGS]

    CLANG_CHAIN[:ARCHIVER][:COMMAND] = "ar"
    CLANG_CHAIN[:ARCHIVER][:ARCHIVE_FLAGS] = "r"

    CLANG_CHAIN[:LINKER][:COMMAND] = "llvm-g++"
    CLANG_CHAIN[:LINKER][:SCRIPT] = "-T"
    CLANG_CHAIN[:LINKER][:USER_LIB_FLAG] = "-l:"
    CLANG_CHAIN[:LINKER][:EXE_FLAG] = "-o"
    CLANG_CHAIN[:LINKER][:LIB_FLAG] = "-l"
    CLANG_CHAIN[:LINKER][:LIB_PATH_FLAG] = "-L"
  end
end
