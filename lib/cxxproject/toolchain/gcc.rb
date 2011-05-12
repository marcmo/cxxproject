require 'cxxproject/toolchain/base'

module Cxxproject
  module Toolchain

    GCCChain = Provider.add("GCC")

    GCCChain[:COMPILER][:CPP].update({
      :COMMAND => "g++",
      :DEFINE_FLAG => "-D",
      :OBJECT_FILE_FLAG => "-o",
      :INCLUDE_PATH_FLAG => "-I",
      :COMPILE_FLAGS => "-c ",
      :DEP_FLAGS => "-MMD -MF " # empty space at the end is important!
    })

    GCCChain[:COMPILER][:C] = GCCChain[:COMPILER][:CPP].clone()
    GCCChain[:COMPILER][:C][:SOURCE_FILE_ENDINGS] = Provider.default[:COMPILER][:C][:SOURCE_FILE_ENDINGS]
    GCCChain[:COMPILER][:C][:COMMAND] = "gcc"

    GCCChain[:COMPILER][:ASM] = GCCChain[:COMPILER][:C].clone()
    GCCChain[:COMPILER][:ASM][:SOURCE_FILE_ENDINGS] = Provider.default[:COMPILER][:ASM][:SOURCE_FILE_ENDINGS]

    GCCChain[:ARCHIVER][:COMMAND] = "ar"
    GCCChain[:ARCHIVER][:ARCHIVE_FLAGS] = "-r"

    GCCChain[:LINKER][:COMMAND] = "g++"
    GCCChain[:LINKER][:SCRIPT] = "-T"
    GCCChain[:LINKER][:USER_LIB_FLAG] = "-l:"
    GCCChain[:LINKER][:EXE_FLAG] = "-o"
    GCCChain[:LINKER][:LIB_FLAG] = "-l"
    GCCChain[:LINKER][:LIB_PATH_FLAG] = "-L"
    GCCChain[:LINKER][:FLAGS] = "-all_load"
    GCCChain[:LINKER][:LIB_PREFIX_FLAGS] = "-Wl,--whole-archive"
    GCCChain[:LINKER][:LIB_POSTFIX_FLAGS] = "-Wl,--no-whole-archive"

  end
end
