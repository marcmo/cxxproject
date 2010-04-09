require 'cxxproject'

describe Dependencies do
  it 'should build the right dependency-chain' do
    lib1 = SourceLibrary.new('1')
    lib2 = SourceLibrary.new('2')
    lib2.dependencies = ['1']
    deps = Dependencies.transitive_dependencies('2')
    deps.map {|d|d.name}.should == ['2', '1']
  end
end
