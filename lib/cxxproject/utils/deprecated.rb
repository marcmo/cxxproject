# modified from http://www.seejohncode.com/2012/01/09/deprecating-methods-in-ruby/
module Deprecated
  attr_accessor :deprecated_warnings

  def reset
    self.deprecated_warnings = {}
  end

  # Define a deprecated alias for a method
  # @param [Symbol] name - name of method to define
  # @param [Symbol] replacement - name of method to (alias)
  def deprecated_alias(name, replacement)
    define_method(name) do |*args, &block|
      self.class.deprecated_warnings ||= {}
      if self.class.deprecated_warnings.has_key?(name) == false
        warn "#{self.class.name}##{name} deprecated (please use ##{replacement})"
        self.class.deprecated_warnings[name] = true
      end
      send replacement, *args, &block
    end
  end

end
