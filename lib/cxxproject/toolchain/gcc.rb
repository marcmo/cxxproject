$toolchainSettings["GCC"] =
{
  :COMPILER =>
    {
  		:CPP => {
		  :COMMAND => "g++",
		  :DEFINE_FLAG => "-D",
		  :OBJECT_FILE_FLAG => "-o",
		  :INCLUDE_PATH_FLAG => "-I",
		  :COMPILE_FLAGS => "-c",
		  :DEFINES => [],
		  :FLAGS => "",
  		  :SOURCE_FILE_ENDINGS => [".cxx", ".cpp", ".c++", ".cc", ".C"]
  		},
  		:C => {
		  :COMMAND => "gcc",
		  :DEFINE_FLAG => "-D",
		  :OBJECT_FILE_FLAG => "-o",
		  :INCLUDE_PATH_FLAG => "-I",
		  :COMPILE_FLAGS => "-c",
		  :DEFINES => [],
		  :FLAGS => "",
		  :SOURCE_FILE_ENDINGS => [".c"]
  		},
  		:ASM => {
		  :COMMAND => "gcc",
		  :DEFINE_FLAG => "-D",
		  :OBJECT_FILE_FLAG => "-o",
		  :INCLUDE_PATH_FLAG => "-I",
		  :COMPILE_FLAGS => "-c",
		  :DEFINES => [],
		  :FLAGS => "",
		  :SOURCE_FILE_ENDINGS => [".asm", ".s", ".S"]
  		}
  	},
  	
  :ARCHIVER =>
    {
	  :COMMAND => "ar",
	  :ARCHIVE_FLAGS => "-r",
	  :FLAGS => ""    
    },
  
  :LINKER =>
    {
	  :COMMAND => "g++",
	  :MUST_FLAGS => "",
	  :SCRIPT => "-T",
	  :USER_LIB_FLAG => "-I:",
	  :EXE_FLAG => "-o",
	  :LIB_FLAG => "-l",
	  :LIB_PATH_FLAG => "-L",
	  #:LIB_PREFIX_FLAGS => "-Wl,--whole-archive",
	  #:LIB_POSTFIX_FLAGS => "-Wl,--no-whole-archive",
	  :LIB_PREFIX_FLAGS => "",
	  :LIB_POSTFIX_FLAGS => "",
	  :FLAGS => "-all_load",    
      :OUTPUT_ENDING => ".exe", # or .elf - needed? Is there a default?
    },
  
  :MAKE =>
    {
	  :COMMAND => "make",
	  :MAKE_FLAGS => "",
	  :FLAGS => "-j",
	  :FILE_FLAG => "-f",
	  :DIR_FLAG => "-C",
	  :CLEAN => "clean"    
    }
}
