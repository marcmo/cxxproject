require 'cxxproject/toolchain/base'

module Cxxproject
  module Toolchain

    DiabChain = Provider.add("Diab")

    DiabChain[:COMPILER][:C].update({
      :COMMAND => "dcc",
      :FLAGS => "-tPPCE200Z6VEN:simple -O -XO -Xsize-opt -Xsmall-const=0 -Xenum-is-best -Xrtti-off -Xexceptions-off -Xexceptions-off -Xenum-is-best -g -Xmake-dependency=6",
      :DEFINE_FLAG => "-D",
      :OBJECT_FILE_FLAG => "-o",
      :INCLUDE_PATH_FLAG => "-I",
      :COMPILE_FLAGS => "-c"
    })

    DiabChain[:COMPILER][:CPP] = DiabChain[:COMPILER][:C]
    DiabChain[:COMPILER][:CPP][:FLAGS].concat(" -Xrtti-off")
    
    DiabChain[:COMPILER][:ASM] = DiabChain[:COMPILER][:C]
    DiabChain[:COMPILER][:ASM][:COMMAND] = "das"
    DiabChain[:COMPILER][:ASM][:FLAGS] = "-tPPCE200Z6VEN:simple -Xisa-vle -g -Xasm-debug-on"
    DiabChain[:COMPILER][:ASM][:COMPILE_FLAGS] = ""
    
    DiabChain[:ARCHIVER][:COMMAND] = "dar"
    DiabChain[:ARCHIVER][:ARCHIVE_FLAGS] = "-r"

    DiabChain[:LINKER][:COMMAND] = "dcc"
    DiabChain[:LINKER][:SCRIPT] = "-Wm"
    DiabChain[:LINKER][:USER_LIB_FLAG] = "-l:"
    DiabChain[:LINKER][:EXE_FLAG] = "-o"
    DiabChain[:LINKER][:LIB_FLAG] = "-l"
    DiabChain[:LINKER][:LIB_PATH_FLAG] = "-L"
    DiabChain[:LINKER][:MAP_FILE_FLAG] = "-Wl,-m6" # no map file if this string is empty, otherwise -Wl,-m6 > abc.map
    DiabChain[:LINKER][:FLAGS] = "-ulink_date_time -uResetConfigurationHalfWord -Wl,-Xstop-on-redeclaration -Wl,-Xstop-on-warning -tPPCE200Z6VEN:simple -Wl,-Xremove-unused-sections -Wl,-Xunused-sections-list"
    DiabChain[:LINKER][:OUTPUT_ENDING] = ".elf"

  end
end
