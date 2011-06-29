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
      return @include_string_self if @include_string_self
      @include_string_self = []
      if includes.length == 0
        @include_string_self << "include"
      else
        @include_string_self = includes
      end
      @include_string_self
    end
  end
end
