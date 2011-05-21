require 'cxxproject/toolchain/gcc'
require 'cxxproject/utils/utils'

module Cxxproject
  module Toolchain

    GCCOSXChain  = Provider.add("GCC_OSX", "GCC")
    GCCOSXChain[:LINKER][:LIB_PREFIX_FLAGS] = ""
    GCCOSXChain[:LINKER][:LIB_POSTFIX_FLAGS] = ""

  end
end
