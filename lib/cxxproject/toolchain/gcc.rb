require 'cxxproject/toolchain/base'

module Cxxproject
  module Toolchain

    GCCChain = Provider.add("GCC")

    GCCChain[:COMPILER][:CPP].update({
      :COMMAND => "g++",
      :DEFINE_FLAG => "-D",
      :OBJECT_FILE_FLAG => "-o",
      :INCLUDE_PATH_FLAG => "-I",
      :COMPILE_FLAGS => "-c"
    })

    GCCChain[:COMPILER][:C] = GCCChain[:COMPILER][:CPP]
    GCCChain[:COMPILER][:C][:COMMAND] = "gcc"

    GCCChain[:COMPILER][:ASM] = GCCChain[:COMPILER][:C]

    GCCChain[:ARCHIVER][:COMMAND] = "ar"
    GCCChain[:ARCHIVER][:ARCHIVE_FLAGS] = "-r"

    GCCChain[:LINKER][:COMMAND] = "g++"
    GCCChain[:LINKER][:SCRIPT] = "-T"
    GCCChain[:LINKER][:USER_LIB_FLAG] = "-l:"
    GCCChain[:LINKER][:EXE_FLAG] = "-o"
    GCCChain[:LINKER][:LIB_FLAG] = "-l"
    GCCChain[:LINKER][:LIB_PATH_FLAG] = "-L"
    GCCChain[:LINKER][:FLAGS] = "-all_load"

    GCCChain[:DEPENDENCY][:COMMAND] = "g++"
    GCCChain[:DEPENDENCY][:FLAGS] = "-MM"

  end
end
