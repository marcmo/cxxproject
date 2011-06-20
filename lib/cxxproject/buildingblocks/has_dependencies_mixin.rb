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

  # inclusive self!!
  def all_dependencies
    @all_dependencies ||= get_transitive_dependencies_internal([self.name])
    @all_dependencies
  end

  # gets alls transitive dependencies and adds them to deps
  def get_transitive_dependencies_internal(deps)
    depsToCheck = []
    depList = helper_dependencies.length > 0 ? helper_dependencies : dependencies
    depList.each do |d|
      if not deps.include?(d)
        deps << d
        depsToCheck << d
        handle_module_dependencies(deps, depsToCheck, d)
      end
    end

    add_child_dependencies(deps, depsToCheck)
    deps
  end

  def add_child_dependencies(deps, depsToCheck)
    # two-step needed to keep order of dependencies for includes, lib dirs, etc
    depsToCheck.each do |d|
      if not ALL_BUILDING_BLOCKS[d]
        raise "ERROR: while reading config file for #{self.name}: dependent building block \"#{d}\" was specified but not found!"
      end
      ALL_BUILDING_BLOCKS[d].get_transitive_dependencies_internal(deps)
    end
  end

  def handle_module_dependencies(deps, depsToCheck, d)
    # deps in modules may be splitted into its contents
    bb = ALL_BUILDING_BLOCKS[d]
    if ModuleBuildingBlock === bb
      bb.content.each do |c|
        if not deps.include?(c.name)
          deps << c.name
          depsToCheck << c.name
        end
      end
    end
  end
end
