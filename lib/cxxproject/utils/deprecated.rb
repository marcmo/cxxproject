# modified from http://www.seejohncode.com/2012/01/09/deprecating-methods-in-ruby/
module Deprecated

  # Define a deprecated alias for a method
  # @param [Symbol] name - name of method to define
  # @param [Symbol] replacement - name of method to (alias)
  def deprecated_alias(name, replacement)
    define_method(name) do |*args, &block|
      @deprecated_warnings = {} unless @deprecated_warnings
      if @deprecated_warnings[name] == nil
        warn "##{name} deprecated (please use ##{replacement})"
        @deprecated_warnings[name] = true
      end
      send replacement, *args, &block
    end
  end

end
