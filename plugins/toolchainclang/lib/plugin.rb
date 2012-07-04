
cxx_plugin do |cxx,bbs,log|

  require 'errorparser/clang_compiler_error_parser'
  toolchain "clang",
    :COMPILER =>
      {
        :CPP => 
          {
            :COMMAND => "clang++",
            :DEFINE_FLAG => "-D",
            :OBJECT_FILE_FLAG => "-o",
            :INCLUDE_PATH_FLAG => "-I",
            :COMPILE_FLAGS => "-c ",
            :DEP_FLAGS => "-MMD -MF ", # empty space at the end is important!
            :ERROR_PARSER => ClangCompilerErrorParser.new
          },
        :C => 
          {
            :BASED_ON => :CPP,
            :COMMAND => "clang",
            :COMPILE_FLAGS => "-c ",
            :DEP_FLAGS => "-MMD -MF ", # empty space at the end is important!
            :ERROR_PARSER => ClangCompilerErrorParser.new
          },
        :ASM =>
          {
            :BASED_ON => :C,
          }
      },
    :LINKER => 
      {
        :COMMAND => "clang++",
        :SCRIPT => "-T",
        :USER_LIB_FLAG => "-l:",
        :EXE_FLAG => "-o",
        :LIB_FLAG => "-l",
        :LIB_PATH_FLAG => "-L"
      },
    :ARCHIVER =>
      {
        :COMMAND => "ar",
        :ARCHIVE_FLAGS => "r"
      }

    # CLANG_CHAIN[:COMPILER][:C] = Utils.deep_copy(CLANG_CHAIN[:COMPILER][:CPP])
    # CLANG_CHAIN[:COMPILER][:ASM] = Utils.deep_copy(CLANG_CHAIN[:COMPILER][:C])



end
