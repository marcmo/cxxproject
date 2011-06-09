require 'cxxproject'
require 'cxxproject/utils/cleanup'

describe BuildingBlock do
  it 'should build the right dependency-chain' do
    lib1 = SourceLibrary.new('1')
    lib2 = SourceLibrary.new('2').set_dependencies(['1'])
    lib3 = SourceLibrary.new('3').set_dependencies(['1'])
    lib4 = SourceLibrary.new('4').set_dependencies(['2', '3'])
    deps = lib4.all_dependencies
    deps.should == ['4', '2', '3', '1']
  end

  it 'should have the right output-directory' do
    Cxxproject.cleanup_rake

    lib1 = SourceLibrary.new('lib1').set_sources(['test.cc'])
    lib1.set_project_dir(File.join(Dir.pwd, 'lib1'))

    lib2 = SourceLibrary.new('lib2').set_sources(['test.cc']).set_output_dir('build2')
    lib2.set_project_dir(File.join(Dir.pwd, 'lib2'))

    cxx = CxxProject2Rake.new([], 'build', GCCChain)
    cxx.prepare_block(lib1)
    cxx.prepare_block(lib2)

    lib1.complete_output_dir.should eq(File.join(Dir.pwd, 'build'))
    lib2.complete_output_dir.should eq(File.join(Dir.pwd, 'lib2', 'build2'))

    Cxxproject.cleanup_rake
  end

end
