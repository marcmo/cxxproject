
module Cxxproject
  class BinaryLibs
    class << self
      def [](*libs)
        libraries = Array.new
        libs.each do |x|
          libraries << BinaryLibrary.new(x)
        end
        libraries
      end
    end
  end

  class EvalContext

    attr_accessor :myblock, :all_blocks

    # must be called to add building blocks
    def cxx_configuration(&block)
      @myblock = block
      @all_blocks = []
    end

    def eval_project(project_text)
      instance_eval(project_text)
    end

    def configuration(*args, &block)
      name = args[0]
      raise "no name given" unless name.is_a?(String) && !name.strip.empty?
      instance_eval(&block)
    end

    def check_hash(hash,allowed)
      hash.keys.map {|k| raise "#{k} is not a valid specifier!" unless allowed.include?(k) }
    end

    # specify an executable
    # hash supports:
    # * :sources
    # * :includes
    # * :dependencies
    # * :libpath
    # * :output_dir
    def exe(name, hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash hash,[:sources,:includes,:dependencies,:libpath,:output_dir]
      bblock = Executable.new(name)
      bblock.set_sources(hash[:sources]) if hash.has_key?(:sources)
      bblock.set_includes(hash[:includes]) if hash.has_key?(:includes)
      calc_lib_searchpath(hash).each { |sp| bblock.add_lib_element(HasLibraries::SEARCH_PATH, sp) }
      if hash.has_key?(:dependencies)
        bblock.set_dependencies(hash[:dependencies])
        hash[:dependencies].each { |d| bblock.add_lib_element(HasLibraries::DEPENDENCY, d) }
      end
      bblock.set_output_dir(hash[:output_dir]) if hash.has_key?(:output_dir)
      all_blocks << bblock
    end

    def calc_lib_searchpath(hash)
      if hash.has_key?(:libpath)
        hash[:libpath]
      else
        if Utils::OS.linux? || Utils::OS.mac?
          ["/usr/local/lib","/usr/lib"]
        elsif Utils::OS.windows?
          ["C:/tool/cygwin/lib", "C:/Tool/cygwin/usr/local/lib"]
        end
      end
    end

    # specify a sourcelib
    # hash supports:
    # * :sources
    # * :includes
    # * :dependencies
    # * :toolchain
    # * :file_dependencies
    # * :output_dir
    def source_lib(name, hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash hash,[:sources, :includes, :dependencies, :toolchain, :file_dependencies, :output_dir]
      raise ":sources need to be defined" unless hash.has_key?(:sources)
      bblock = SourceLibrary.new(name)
      bblock.set_sources(hash[:sources])
      bblock.set_includes(hash[:includes]) if hash.has_key?(:includes)
      bblock.set_tcs(hash[:toolchain]) if hash.has_key?(:toolchain)
      if hash.has_key?(:dependencies)
        bblock.set_dependencies(hash[:dependencies]) 
        hash[:dependencies].each { |d| bblock.add_lib_element(HasLibraries::DEPENDENCY, d) }
      end
      bblock.file_dependencies = hash[:file_dependencies] if hash.has_key?(:file_dependencies)
      bblock.set_output_dir(hash[:output_dir]) if hash.has_key?(:output_dir)
      all_blocks << bblock
    end

    # specify some binary libs
    # returns all binary libs as array
    def bin_libs(*names)
      res = []
      mapped = names.map{|n|n.to_s}
      mapped.each do |name|
        res << BinaryLibrary.new(name)
      end
      mapped
    end

    def compile(name, hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash hash,[:sources,:includes]
      bblock = SingleSource.new(name)
      bblock.set_sources(hash[:sources]) if hash.has_key?(:sources)
      bblock.set_includes(hash[:includes]) if hash.has_key?(:includes)
      all_blocks << bblock
    end

    def custom(name, hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash hash,[:execute]
      bblock = CustomBuildingBlock.new(name)
      bblock.set_actions(hash[:execute]) if hash.has_key?(:execute)
      all_blocks << bblock
    end

  end
end
