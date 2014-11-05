require 'cxxproject/utils/utils'
require 'cxxproject/toolchain/provider'
require 'cxxproject/errorparser/error_parser'
require 'cxxproject/errorparser/gcc_lint_error_parser'

module Cxxproject
  module Toolchain

    GCCLintChain = Provider.add("GCC_Lint")

    GCCLintChain[:COMPILER][:CPP].update({
      :COMMAND => "lint-nt.exe",
      :DEFINE_FLAG => "-D",
      :INCLUDE_PATH_FLAG => "-I",
      :COMPILE_FLAGS => ["-b","-\"format=%f%(:%l:%) %t %n: %m\"", "-width(0)", "-hF1"], # array, not string!
    })

    GCCLintChain[:COMPILER][:CPP][:ERROR_PARSER] = GCCLintErrorParser.new
      
  end
end
