# modified from http://www.seejohncode.com/2012/01/09/deprecating-methods-in-ruby/
module Deprecated
  class << self
    attr_accessor :deprecated_warnings
  end

  def Deprecated.reset
    Deprecated.deprecated_warnings = {}
  end

  Deprecated.deprecated_warnings = {}
  # Define a deprecated alias for a method
  # @param [Symbol] name - name of method to define
  # @param [Symbol] replacement - name of method to (alias)
  def deprecated_alias(name, replacement)
    define_method(name) do |*args, &block|
      if Deprecated.deprecated_warnings.has_key?(name) == false
        warn "##{name} deprecated (please use ##{replacement})"
        Deprecated.deprecated_warnings[name] = true
      end
      send replacement, *args, &block
    end
  end

end
