module HasDependencies

  def dependencies
    @dependencies ||= []
  end

  def set_dependencies(deps)
    @dependencies = deps.map { |dep| dep.instance_of?(String) ? dep : dep.name }
    self
  end

  # if set, includes and libs are taken from this array, not from @dependencies.
  # task deps are still taken from @dependencies.
  # use case: circular deps are allowed on "include-level", but not on "task-level".
  def helper_dependencies
    @helper_dependencies ||= []
  end

  def set_helper_dependencies(deps)
    @helper_dependencies = deps.map { |dep| dep.instance_of?(String) ? dep : dep.name }
  end

  def all_dependencies(stack = Set.new)
    return @all_dependencies if @all_deps_calculated

    @all_dependencies = [self]

    depList = helper_dependencies.length > 0 ? helper_dependencies : dependencies
    depList.each do |d|
      bb = ALL_BUILDING_BLOCKS[d]
      if not bb
        raise "ERROR: while reading config file for #{self.name}: dependent building block \"#{d}\" was specified but not found!"
      end
      @all_dependencies << bb
      handle_module_dependencies(bb)
    end

    stack.add(self)
    # two-step needed to keep order of dependencies for includes, lib dirs, etc
    @all_dependencies.dup.each do |d|
      next if stack.include?d
      @all_dependencies.concat(d.all_dependencies(stack))
    end
    stack.delete(self)

    @all_dependencies.uniq!
    @all_deps_calculated = true
    @all_dependencies
  end

  def handle_module_dependencies( bb)
    # deps in modules may be splitted into its contents
    if ModuleBuildingBlock === bb
      bb.content.each do |c|
        @all_dependencies << c
      end
    end
  end

end
