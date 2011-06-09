require 'cxxproject/extensions/rake_listener_ext.rb'

describe Rake::Task do

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

end
