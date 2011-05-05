module HasDependencies

  def dependencies
    @dependencies ||= []
  end
  def set_dependencies(deps)
    @dependencies = deps.map { |dep| dep.instance_of?(String) ? dep : dep.name }
    self
  end

  # will be calculated at the beginning of creating the building block task
  def all_dependencies
    @all_dependencies ||= []
  end

  # inclusive self!!
  def calc_transitive_dependencies
    deps = [self.name] # needed due to circular deps
    @all_dependencies = get_transitive_dependencies_internal(deps)
  end

  def get_transitive_dependencies_internal(deps)
    depsToCheck = []
    dependencies.each do |d|
      if not deps.include?d
        deps << d
        depsToCheck << d
      end
    end

    # two-step needed to keep order of dependencies for includes, lib dirs, etc
    depsToCheck.each do |d|
      ALL_BUILDING_BLOCKS[d].get_transitive_dependencies_internal(deps)
    end
    deps

  end

end
