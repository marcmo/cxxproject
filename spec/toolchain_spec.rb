GCC_JSON = File.join(File.dirname(__FILE__),"..","lib","cxxproject","toolchain","gcc.json")
require 'cxxproject/toolchain/toolchain'

describe String do
  it 'should correctly load toolchain from json file' do
    tc = Toolchain.new(GCC_JSON)
    tc.name.should == "gcc"
    tc.compiler.cpp.command.should == "g++"
    tc.compiler.c.source_file_endings.should == [".c"]
    tc.linker.output_ending == ".exe"
  end

  it 'should be possible to add list items to existing settings' do
    tc = Toolchain.new(GCC_JSON)
    tc.compiler.c.source_file_endings.should == [".c"]
    tc.compiler.c.source_file_endings << ".cc"
    tc.compiler.c.source_file_endings.should == [".c",".cc"]
    tc.compiler.c.source_file_endings << ".aa"
    tc.compiler.c.source_file_endings.should == [".c",".cc",".aa"]
  end

  it "should be possible to replace existing settings" do
    tc = Toolchain.new(GCC_JSON)
    tc.compiler.c.source_file_endings.should == [".c"]
    tc.compiler.c.source_file_endings = [".cc"]
    tc.compiler.c.source_file_endings.should == [".cc"]
  end

end
