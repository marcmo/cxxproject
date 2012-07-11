class Hash
  def method_missing(m, *args, &block)
    if m.to_s =~ /(.*)=$/ # was assignment
      self[$1] = args[0]
    else
      fetch(m.to_s, nil)
    end
  end
  def recursive_merge(h)
    self.merge!(h) {|key, _old, _new| if _old.class == Hash then _old.recursive_merge(_new) else _new end  }
  end
end
