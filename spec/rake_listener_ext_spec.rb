require 'cxxproject/extensions/rake_listener_ext.rb'
require 'cxxproject/utils/cleanup'

describe Rake::Task do

  it "should call a listener for prerequisites and execute" do

    Cxxproject.cleanup_rake

    t = task "test"

    l = mock
    Rake::add_listener(l)

    l.should_receive(:before_prerequisites).with('test')
    l.should_receive(:after_prerequisites).with('test')
    l.should_receive(:before_execute).with('test')
    l.should_receive(:after_execute).with('test')
    t.invoke

    Rake::remove_listener(l)

    t.invoke

    Cxxproject.cleanup_rake
  end

end
