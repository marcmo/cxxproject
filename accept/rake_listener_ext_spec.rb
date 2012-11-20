require 'cxxproject'
require 'cxxproject/ext/rake_listener.rb'
require 'cxxproject/utils/cleanup'

describe Rake::Task do

  before(:each) do
    Cxxproject::Utils.cleanup_rake
  end
  after(:each) do
    Cxxproject::Utils.cleanup_rake
  end


 it "should call a listener for prerequisites and execute" do
    task "mypre"
    t = task "test" => "mypre"

    l = mock
    Rake::add_listener(l)

    l.should_receive(:before_execute).with('mypre')
    l.should_receive(:after_execute).with('mypre')
    l.should_receive(:before_prerequisites).with('mypre')
    l.should_receive(:after_prerequisites).with('mypre')
    l.should_receive(:before_prerequisites).with('test')
    l.should_receive(:after_prerequisites).with('test')
    l.should_receive(:before_execute).with('test')
    l.should_receive(:after_execute).with('test')
    t.invoke

    Rake::remove_listener(l)

    t.invoke
  end

  class DummyListener
    def calls
      @calls ||= []
    end
    def after_execute(name)
      c = calls
      c << name
    end
  end

  it "should work with only half implemented rake-listener" do
    task "mypre"
    t = task "test" => "mypre"
    l = DummyListener.new
    Rake::add_listener(l)
    t.invoke
    Rake::remove_listener(l)
    l.calls.should eq(['mypre', 'test'])
  end

end
