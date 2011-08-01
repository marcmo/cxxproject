require 'spec_helper'
require 'cxxproject'
require 'cxxproject/utils/cleanup'

RSPECDIR = File.dirname(__FILE__)

describe CxxProject2Rake do

  def execute_all_tasks(tasks)
    tasks.each do |t|
      t.invoke
    end
  end

  def fresh_cxx(outputdir,base)
    Cxxproject::Utils.cleanup_rake
    project_configs = nil
    cd base do # have to be relative to base
      project_configs = Dir.glob('**/project.rb')
    end
    CxxProject2Rake.new(project_configs, outputdir, GCCChain, base)
  end


#  def is_older? fileA, fileB
#    File.mtime(fileA) < File.mtime(fileB)
#  end

#  def is_newer? fileA, fileB
#    File.mtime(fileA) > File.mtime(fileB)
#  end

  def test_on_level(base, outputdir)
    libOne = "#{outputdir}/libs/lib1.a"
    libTwo = "#{outputdir}/libs/lib2.a"
    exe = "#{outputdir}/basic.exe"
    exe2 = "#{outputdir}/debug.exe"

    rm_r outputdir if File.directory?(outputdir)
    tasks = fresh_cxx(outputdir, base).all_tasks
    CLOBBER.each { |fn| rm_r fn rescue nil }

    [libOne,libTwo,exe,exe2].all? {|f| File.exists?(f).should be_false }

    execute_all_tasks(tasks)

    [libOne,libTwo,exe,exe2].all? {|f| File.exists?(f).should be_true }

    # cleanup
    rm_r outputdir if File.directory?(outputdir)
    Cxxproject::Utils.cleanup_rake
  end

  it 'should resolve paths on different levels' do
    outputdir = 'output'

    cd("#{RSPECDIR}/testdata/multiple_levels", :verbose => false) do
      test_on_level(".", outputdir)
    end

    cd("#{RSPECDIR}/testdata/multiple_levels/mainproject", :verbose => false) do
      test_on_level("..", outputdir)
    end

    cd("#{RSPECDIR}/testdata", :verbose => false) do
      test_on_level("multiple_levels/", outputdir)
    end
  end

end

