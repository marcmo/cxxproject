module Cxxproject
  module HasLibraries
    LIB = :lib
    USERLIB = :userlib
    LIB_WITH_PATH = :lib_with_path
    SEARCH_PATH = :search_path
    DEPENDENCY = :dependency

    def lib_elements
      @lib_elements ||= []
    end

    # value: can be string or building block
    def add_lib_element(type, value, front = false)
      elem = [type, value.instance_of?(String) ? value : value.name]
      if front
        lib_elements.unshift(elem)
      else
        lib_elements << elem
      end
    end

    # 1. element: type
    # 2. element: name, must not be a building block
    def add_lib_elements(array_of_tuples, front = false)
      if front
        @lib_elements = array_of_tuples+lib_elements
      else
        lib_elements.concat(array_of_tuples)
      end
    end

  end
end
