describe Cxxproject::HasSources do

  include Cxxproject::HasSources
  
  def dummy_toolchain
    {:COMPILER =>
       {
         :CPP => {:COMMAND => :cpp_compiler},
         :C => {:COMMAND => :c_compiler},
         :ASM => {:COMMAND => :asm_compiler}}}
  end
  
  it 'should fetch the compilers for all types' do
    get_compiler_command(dummy_toolchain, :CPP).should eq(:cpp_compiler)
    get_compiler_command(dummy_toolchain, :C).should eq(:c_compiler)
    get_compiler_command(dummy_toolchain, :ASM).should eq(:asm_compiler)
  end

  it 'should prefer values from env variables' do
    ENV['CXX'] = 'cxx'
    ENV['CC'] = 'c'
    get_compiler_command(dummy_toolchain, :CPP).should eq('cxx')
    get_compiler_command(dummy_toolchain, :C).should eq('c')
    ENV.delete('CXX')
    ENV.delete('C')
  end
  
end
