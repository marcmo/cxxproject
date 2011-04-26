require 'cxxproject/toolchain/diab'
require 'cxxproject/toolchain/gcc'

module Cxxproject
module Toolchain

class Provider
		
	def self.[](name)
		return @@settings[name] if @@settings.include? name
		nil
	end
	
end

end
end