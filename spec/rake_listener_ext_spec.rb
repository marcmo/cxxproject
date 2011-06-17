$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'cxxproject'
require 'cxxproject/extensions/rake_listener_ext.rb'
require 'cxxproject/utils/cleanup'

describe Rake::Task do

 it "should call a listener for prerequisites and execute" do
    Cxxproject.cleanup_rake

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

    Cxxproject.cleanup_rake
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
    Cxxproject.cleanup_rake

    task "mypre"
    t = task "test" => "mypre"
    l = DummyListener.new
    Rake::add_listener(l)
    t.invoke
    Rake::remove_listener(l)
    l.calls.should eq(['mypre', 'test'])

    Cxxproject.cleanup_rake
  end

end
