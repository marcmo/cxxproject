require 'cxxproject'

describe Dependencies do
  it 'should build the right dependency-chain' do
    lib1 = SourceLibrary.new(nil, '1')
    lib2 = SourceLibrary.new(nil, '2').set_dependencies(['1'])
    lib3 = SourceLibrary.new(nil, '3').set_dependencies(['1'])
    lib4 = SourceLibrary.new(nil, '4').set_dependencies(['2', '3'])
    deps = Dependencies.transitive_dependencies(['4'])
    deps.map {|d|d.name}.should == ['4', '2', '3', '1']
  end
end
