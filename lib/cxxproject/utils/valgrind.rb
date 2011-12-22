module Cxxproject
  class Valgrind
    @@valgrind_available = nil
    def self.available?
      if @@valgrind_available == nil
        @@valgrind_available = `which valgrind  2>&1`.strip.length > 0
      end
      return @@valgrind_available
    end
  end
end
