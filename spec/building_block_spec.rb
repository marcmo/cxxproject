require 'cxxproject'

describe BuildingBlock do
  it 'should build the right dependency-chain' do
    lib1 = SourceLibrary.new('1')
    lib2 = SourceLibrary.new('2').set_dependencies(['1'])
    lib3 = SourceLibrary.new('3').set_dependencies(['1'])
    lib4 = SourceLibrary.new('4').set_dependencies(['2', '3'])
    deps = lib4.calc_transitive_dependencies
    deps.should == ['4', '2', '3', '1']
  end
end
