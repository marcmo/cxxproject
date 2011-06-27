module AttributeHelper

  def lazy_attribute_with_default(symbol, initial_value)
    define_method(symbol) do
      name = "@#{symbol}"
      h = instance_variable_get(name)
      if h == nil
        instance_variable_set(name, initial_value)
        h = initial_value
      end
      h
    end
  end

end
