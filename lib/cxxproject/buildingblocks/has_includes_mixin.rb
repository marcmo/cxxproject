module Cxxproject
  module HasIncludes
    def includes
      @includes ||= []
    end
    def set_includes(x)
      @includes = x
      self
    end
    def include_string_self
      @include_string_self ||= []
    end
  end
end
