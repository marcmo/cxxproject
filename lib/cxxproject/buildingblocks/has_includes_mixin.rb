module HasIncludes
  def includes
    @includes ||= []
  end
  def set_includes(x)
    @includes = x
    self
  end
end
