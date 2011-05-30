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

  # # will be calculated at the beginning of creating the building block task
  # def all_dependencies
  #   @all_dependencies ||= []
  # end

  # inclusive self!!
  def calc_transitive_dependencies
    deps = [self.name]
    @all_dependencies ||= get_transitive_dependencies_internal(deps)
    @all_dependencies
  end

  def get_transitive_dependencies_internal(deps)
    depsToCheck = []
    depList = helper_dependencies.length > 0 ? helper_dependencies : dependencies
    depList.each do |d|
      if not deps.include?d
        deps << d
        depsToCheck << d
      end
    end

    # two-step needed to keep order of dependencies for includes, lib dirs, etc
    depsToCheck.each do |d|
      begin
        raise "ERROR: while reading config file for #{self.name}: dependent building block \"#{d}\" was specified but not found!" unless ALL_BUILDING_BLOCKS[d]
        ALL_BUILDING_BLOCKS[d].get_transitive_dependencies_internal(deps)
      rescue Exception => e
        puts e
        exit
      end
    end
    deps

  end

end
