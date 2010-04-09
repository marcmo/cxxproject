require 'cxxproject'

describe Dependencies do
  it 'should build the right dependency-chain' do
    lib1 = SourceLibrary.new('1')
    lib2 = SourceLibrary.new('2')
    lib2.dependencies = ['1']
    lib3 = SourceLibrary.new('3')
    lib3.dependencies = ['1']
    lib4 = SourceLibrary.new('4')
    lib4.dependencies = ['2', '3']
    deps = Dependencies.transitive_dependencies(['4'])
    deps.map {|d|d.name}.should == ['4', '2', '3', '1']
  end
  it 'should create .d files' do
    pending
    1.should == 0
  end
end
