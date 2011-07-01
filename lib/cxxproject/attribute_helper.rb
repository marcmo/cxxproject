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

  def lazy_attribute_from_calculation(symbol, calc_symbol)
    define_method(symbol) do
      name = "@#{symbol}"
      h = instance_variable_get(name)
      if h == nil
        v = self.send(calc_symbol)
        instance_variable_set(name, v)
        h = v
      end
      h
    end
  end

end
