require 'cxxproject'

describe Configuration do
  it 'should find all configs till the root' do
    cd('testdata/configuration/example_project', :verbose => false) do
      c = Configuration.new(Dir.getwd)
      c.configs.size.should >= 2
    end
  end
  it 'should find values in each config file' do
    cd('testdata/configuration/example_project', :verbose => false) do
      c = Configuration.new(Dir.getwd)
      c.get_value(:test1).should == 'test1value'
      c.get_value(:test2).should == 'test2value'
    end
  end

  it 'should deliver the most special values if values are defined on several levels' do 
    cd('testdata/configuration/example_project', :verbose => false) do
      c = Configuration.new(Dir.getwd)
      c.get_value(:test3).should == 'test1value'
    end
  end

end
