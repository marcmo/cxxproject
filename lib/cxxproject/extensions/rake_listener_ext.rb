require 'rake'

module Rake

  def self.add_listener(l)
    get_listener() << l
  end

  def self.get_listener
    @@listener ||= []
  end

  def self.remove_listener(l)
    get_listener().delete(l)
  end

  class MultiTask
    invoke_prerequisites_original = self.instance_method(:invoke_prerequisites)
    define_method(:invoke_prerequisites) do |task_args, invocation_chain|
      Rake::get_listener().each {|l|l.before_prerequisites(name)}
      invoke_prerequisites_original.bind(self).call(task_args, invocation_chain)
      Rake::get_listener().each {|l|l.after_prerequisites(name)}
      if !needed?
        Rake::get_listener().each{|l|l.after_execute(name)}
      end
    end
  end

  class Task

    invoke_prerequisites_original = self.instance_method(:invoke_prerequisites)
    execute_original = self.instance_method(:execute)

    define_method (:invoke_prerequisites) do |task_args, invocation_chain|
      Rake::get_listener().each {|l|l.before_prerequisites(name)}
      invoke_prerequisites_original.bind(self).call(task_args, invocation_chain)
      Rake::get_listener().each {|l|l.after_prerequisites(name)}
      if !needed?
        Rake::get_listener().each{|l|l.after_execute(name)}
      end
    end

    define_method(:execute) do |args|
      Rake::get_listener.each {|l|l.before_execute(name)}
      execute_original.bind(self).call(args)
      Rake::get_listener.each {|l|l.after_execute(name)}
    end

  end

end

