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
      
      tmp = @project_dir + "__DUMMY__"
      if includes.length == 0
        # convinience to add include if no includes are given
        @include_string_self << File.relFromTo("include", @project_dir)
      else
        includes.each { |k| @include_string_self << File.relFromTo(k, @project_dir) }
      end      
      @include_string_self
    end
  end
end
