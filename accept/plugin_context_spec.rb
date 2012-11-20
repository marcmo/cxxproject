require 'cxxproject/plugin_context'


describe Cxxproject::PluginContext do
  it "should copy cpp settings to c settings" do
    toolchain = {:COMPILER => {
                  :CPP => { :DEFINE_FLAG => "-D", :COMMAND => "clang++" },
                  :C => { :BASED_ON => :CPP, :COMMAND => "clang" }
                }}
    expected = {:COMPILER => {
                  :CPP => { :DEFINE_FLAG => "-D", :COMMAND => "clang++" },
                  :C => { :DEFINE_FLAG => "-D", :COMMAND => "clang" }
                }}
    Cxxproject::PluginContext.expand(toolchain).should == expected
  end

  it "should fully resolve all :BASED_ON sections" do
    toolchain = {:COMPILER => {
                  :CPP => { :DEFINE_FLAG => "-D", :COMMAND => "clang++" },
                  :C => { :BASED_ON => :CPP, :COMMAND => "clang" },
                  :ASM => { :BASED_ON => :C }
                }}
    expected = {:COMPILER => {
                  :CPP => { :DEFINE_FLAG => "-D", :COMMAND => "clang++" },
                  :C => { :DEFINE_FLAG => "-D", :COMMAND => "clang" },
                  :ASM => { :DEFINE_FLAG => "-D", :COMMAND => "clang" }
                }}
    Cxxproject::PluginContext.expand(toolchain).should == expected
  end

  it "should find out if extension is needed" do
    toolchain = {:COMPILER => {
                  :CPP => { :DEFINE_FLAG => "-D", :COMMAND => "clang++" },
                  :C => { :BASED_ON => :CPP, :COMMAND => "clang" } }}
    toolchain2 = {:COMPILER => {
                  :CPP => { :DEFINE_FLAG => "-D", :COMMAND => "clang++" },
                  :C => { :COMMAND => "clang" } }}
    Cxxproject::PluginContext.needs_expansion(toolchain).should == true
    Cxxproject::PluginContext.needs_expansion(toolchain2).should == false
  end

  it "should find a toolchain to expand" do
    toolchain = {:COMPILER => {
                  :CPP => { :DEFINE_FLAG => "-D", :COMMAND => "clang++" },
                  :C => { :BASED_ON => :CPP, :COMMAND => "clang" }
                }}
    Cxxproject::PluginContext.find_toolchain_subhash(toolchain).should == toolchain[:COMPILER][:C]
  end

  it "should find a toolchain element by name" do
    toolchain = {:COMPILER => {
                  :CPP => { :DEFINE_FLAG => "-D", :COMMAND => "clang++" },
                  :C => { :BASED_ON => :CPP, :COMMAND => "clang" }
                }}
    Cxxproject::PluginContext.find_toolchain_element(toolchain, :CPP).should == toolchain[:COMPILER][:CPP]
  end
end
