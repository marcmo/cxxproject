class Dependencies
  def self.transitive_dependencies(lib)
    bb = ALL_BUILDING_BLOCKS[lib]
    if !bb
      raise "dependency not found #{lib}"
    end
    res = [bb]
    bb.dependencies.each do |d|
      new_one = transitive_dependencies(d)
      res += new_one
    end
    return res
  end
end
