require 'cxxproject'
require 'cxxproject/utils/cleanup'

describe Cxxproject::BuildingBlock do
  compiler = 'gcc'

  before(:each) do
    Cxxproject::Utils.cleanup_rake
  end

  after(:each) do
    Cxxproject::Utils.cleanup_rake
  end

  it 'should collect the dependencies for a single lib' do
    lib1 = Cxxproject::SourceLibrary.new('1')
    lib1.collect_dependencies().should == [lib1]
  end

  it 'should collect the dependencies for a single lib with one dep' do
    lib1 = Cxxproject::SourceLibrary.new('1')
    lib2 = Cxxproject::SourceLibrary.new('2').set_dependencies(['1'])
    lib2.collect_dependencies().should == [lib2, lib1]
  end

  it 'should build the right dependency-chain' do
    lib1 = Cxxproject::SourceLibrary.new('1').set_dependencies(['2'])
    lib2 = Cxxproject::SourceLibrary.new('2')
    lib3 = Cxxproject::SourceLibrary.new('3').set_dependencies(['2', '1'])
    lib3.collect_dependencies().should == [lib3, lib1, lib2]
  end

  it 'should build the right dependency-chain for custom blocks' do
    lib1 = Cxxproject::SourceLibrary.new('1')
    lib2 = Cxxproject::SourceLibrary.new('2').set_dependencies(['1'])
    lib3 = Cxxproject::SourceLibrary.new('3').set_dependencies(['1', '2'])
    lib4 = Cxxproject::SourceLibrary.new('4').set_dependencies(['1', '2', '3'])
    lib4.collect_dependencies().should == [lib4, lib3, lib2, lib1]
  end

  it 'should generate an error if building block names conflict' do
    expect {
      Cxxproject::SourceLibrary.new('1')
      Cxxproject::SourceLibrary.new('1')
    }.to raise_exception
  end

  it 'should be possible to give several binary libs with the same name' do
    Cxxproject::BinaryLibrary.new('1')
    Cxxproject::BinaryLibrary.new('1')
  end

  it 'should be an error if the same name is used for different kinds of building blocks' do
    expect {
      Cxxproject::BinaryLibrary.new('1')
      Cxxproject::SourceLibrary.new('1')
    }.to raise_exception
  end

  it 'should handle whole archive' do
    # TODO ... clean up api and also this test
    l1 = Cxxproject::SourceLibrary.new('1', true)
    l1.output_dir = 'out'
    l1.complete_init
    l2 = Cxxproject::SourceLibrary.new('2', true)
    l2.output_dir = 'out'
    l2.complete_init
    exe = Cxxproject::Executable.new('test')
    deps = ['1', '2']
    exe.set_dependencies(deps)
    exe.complete_init
    exe.linker_lib_string({:START_OF_WHOLE_ARCHIVE => 'start', :END_OF_WHOLE_ARCHIVE => 'end'}).should == ['start', 'out/lib2.a', 'end', 'start', 'out/lib1.a', 'end']
    # TODO add a test for recursive whole archive libs a lib that should be whole and that has dependencies to whole libs
  end

  it 'should have tags' do
    s1 = Cxxproject::SourceLibrary.new('s1')
    s1.tags = ["a", "b"].to_set
  end

  it 'should be possible to find building blocks by tag' do
    s1 = Cxxproject::SourceLibrary.new('s1')
    s1.tags = ["a", "b"].to_set
    s2 = Cxxproject::SourceLibrary.new('s2')
    s2.tags = ["b"].to_set

    Cxxproject::find_by_tag('a').to_set == [s1].to_set
    Cxxproject::find_by_tag('b').to_set == [s1, s2].to_set
  end

=begin
  it 'should have the right output-directory' do
    lib1 = Cxxproject::SourceLibrary.new('lib1').set_sources(['test.cc'])
    lib1.set_project_dir(File.join(Dir.pwd, 'lib1'))

    lib2 = Cxxproject::SourceLibrary.new('lib2').set_sources(['test.cc']).set_output_dir('build2')
    lib2.set_project_dir(File.join(Dir.pwd, 'lib2'))

    cxx = CxxProject2Rake.new([], 'build', compiler)

    cxx.prepare_block(lib1, Provider[compiler], "build")
    cxx.prepare_block(lib2, Provider[compiler], "build")

    lib1.complete_output_dir.should eq(File.join(Dir.pwd, 'build'))
    lib2.complete_output_dir.should eq(File.join(Dir.pwd, 'lib2', 'build2'))
  end

  it 'should raise exception if building block cannot be resolved' do
    expect do
      lib1 = Cxxproject::SourceLibrary.new('1').set_dependencies(['unresolved'])
      cxx = CxxProject2Rake.new([], 'build', compiler)
    end.to raise_exception(RuntimeError, 'Error: while reading config file for 1: dependent building block "unresolved" was specified but not found!')
  end
=end
end
