require 'cxxproject/utils/utils'
require 'cxxproject/toolchain/provider'
require 'cxxproject/errorparser/error_parser'
require 'cxxproject/errorparser/gcc_lint_error_parser'

module Cxxproject
  module Toolchain

    class GCC_Param
    
          def initialize
            @incs = []
            @defs = []
          end
          
          def init_vars
            @incs = []
            @defs = []
              
            begin
              isCygwin = system("cygpath --version > /dev/null 2>&1")
              
              incStart = false
              defRegex = /^#define (\S+) (.*)/
              
              gccString = `echo "" | g++ -x c++ -E -dM -v - 2>&1` 
              
              gccString.lines.map(&:chomp).each do |line|
                if line.include?"#include <...> search starts here:"
                  incStart = true
                elsif line.include?"End of search list."
                  incStart = false
                elsif incStart
                  inc = line.strip
                  inc = `cygpath -w #{line.strip}`.strip if isCygwin
                  @incs << "--i#{inc}"
                elsif regRes = line.match(defRegex)
                  @defs << "-D#{regRes[1]}=\"#{regRes[2]}\""
                end
              end
              
            rescue Exception=>e
              Printer.printError "Error: could not determine GCC's internal includes and defines"
              raise
            end
            
          end
          
          def internalIncludes
            @incs
          end
          
          def internalDefines
            @defs
          end
        end      
    
    GCCLintChain = Provider.add("GCC_Lint")

    GCCLintChain[:COMPILER][:CPP].update({
      :COMMAND => "lint-nt.exe",
      :DEFINE_FLAG => "-D",
      :INCLUDE_PATH_FLAG => "-I",
      :COMPILE_FLAGS => ["-b","-\"format=%f%(:%l:%) %t %n: %m\"", "-width(0)", "-hF1"], # array, not string!
    })

    GCCLintChain[:COMPILER][:CPP][:ERROR_PARSER] = GCCLintErrorParser.new
    GCCLintChain[:LINT_PARAM] = GCC_Param.new

    
      
  end
end
