
cxx_plugin do |cxx,bbs,log|

   toolchain "gcc",
    :COMPILER =>
      {
        :CPP => 
          {
            :COMMAND => "g++",
            :DEFINE_FLAG => "-D",
            :OBJECT_FILE_FLAG => "-o",
            :INCLUDE_PATH_FLAG => "-I",
            :COMPILE_FLAGS => "-c ",
            :DEP_FLAGS => "-MMD -MF ", # empty space at the end is important!
          }
      }

end
