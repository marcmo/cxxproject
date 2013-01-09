require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/source_library'
require 'cxxproject/buildingblocks/executable'

describe Cxxproject::Executable do
  SOURCE_NAME = './hello.cpp'
  OUTDIR = 'out'
  COMMAND = 'cmd'
  MUSTFLAG1 = '-mustflag1'
  MUSTFLAG2 = '-mustflag2'
  FLAGS = '-flags'
  EXE_FLAG = 'exeflag'
  OUTPUT_ENDING = '.exe'
  LIB_PREFIX = 'libprefix'
  LIB_POSTFIX = 'libpostfix'
  START_OF_WHOLE_ARCHIVE = 'startofwholearchive'
  END_OF_WHOLE_ARCHIVE = 'endofwholearchive'
  before(:each) do
    File.open(SOURCE_NAME, 'w') do |io|
      io.puts('// just for testing')
    end
  end
  after(:each) do
    File.delete(SOURCE_NAME)
  end

  it 'should be there' do
    lib1 = Cxxproject::SourceLibrary.new('lib1', true)
    lib1.set_output_dir(OUTDIR)
    lib1.set_project_dir('.')
    lib1.set_sources([SOURCE_NAME])
    lib1.complete_init
    exe = Cxxproject::Executable.new('test')
    exe.set_output_dir(OUTDIR)
    exe.set_project_dir('.')
    exe.set_sources([SOURCE_NAME])
    exe.set_dependencies(['lib1'])
    exe.complete_init
    toolchain = double('Toolchain')
    linker = double('Linker')
    linker.stub(:[]).with(:COMMAND).and_return(COMMAND)
    linker.stub(:[]).with(:MUST_FLAGS).and_return("#{MUSTFLAG1} #{MUSTFLAG2}")
    linker.stub(:[]).with(:FLAGS).and_return([FLAGS])
    linker.stub(:[]).with(:EXE_FLAG).and_return(EXE_FLAG)
    linker.stub(:[]).with(:OUTPUT_ENDING).and_return(OUTPUT_ENDING)
    linker.stub(:[]).with(:LIB_PREFIX_FLAGS).and_return(LIB_PREFIX)
    linker.stub(:[]).with(:LIB_POSTFIX_FLAGS).and_return(LIB_POSTFIX)
    linker.stub(:[]).with(:START_OF_WHOLE_ARCHIVE).and_return(START_OF_WHOLE_ARCHIVE)
    linker.stub(:[]).with(:END_OF_WHOLE_ARCHIVE).and_return(END_OF_WHOLE_ARCHIVE)
    toolchain.stub(:[]).and_return(linker)
    exe.set_tcs(toolchain)
    exe.convert_to_rake
    exe.calc_command_line.should eq([COMMAND, MUSTFLAG1, MUSTFLAG2, FLAGS, EXE_FLAG, "#{OUTDIR}/#{exe.name}#{OUTPUT_ENDING}", LIB_PREFIX, START_OF_WHOLE_ARCHIVE, "#{lib1.get_archive_name}", END_OF_WHOLE_ARCHIVE, LIB_POSTFIX])
  end

  

end
