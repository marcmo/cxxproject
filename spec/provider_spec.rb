require 'cxxproject/toolchain/provider'
require 'cxxproject/utils/utils'

describe Cxxproject::Toolchain::Provider do

  it 'should default to the running system' do
    Cxxproject::Toolchain::Provider.default[:TARGET_OS].should eq(Cxxproject::Utils::OS.os)
  end

  it 'should be possible to change this' do
    old = Cxxproject::Toolchain::Provider.default[:TARGET_OS]
    Cxxproject::Toolchain::Provider.default[:TARGET_OS] = :something
    Cxxproject::Toolchain::Provider.default[:TARGET_OS].should eq(:something)
    Cxxproject::Toolchain::Provider.default[:TARGET_OS] = old
    Cxxproject::Toolchain::Provider.default[:TARGET_OS].should eq(Cxxproject::Utils::OS.os)
  end

end
