require 'cxxproject/buildingblocks/building_blocks'
require 'cxxproject/utils/cleanup'

describe Cxxproject::Linkable do
  SOURCE_NAME = './hello.cpp'
  OUTDIR = "#{Dir.pwd}/out"
  COMMAND = 'cmd'
  MUSTFLAG1 = '-mustflag1'
  MUSTFLAG2 = '-mustflag2'
  FLAGS = '-flags'
  EXE_FLAG = 'exeflag'
  LIB_PREFIX = 'libprefix'
  LIB_POSTFIX = 'libpostfix'
  START_OF_WHOLE_ARCHIVE = {:UNIX => 'startofwholearchive', :OSX => 'startofwholearchiveforosx'}
  END_OF_WHOLE_ARCHIVE = {:UNIX => 'endofwholearchive', :OSX => 'endofwholearchiveforosx'}
  LIB_FLAG = 'libflag'
  LIB_PATH_FLAG = 'libpathflag'
  USER_LIB_FLAG = 'userlibflag'
  SHARED_FLAG = '-shared'
  OUTPUT_PREFIX = {:SHARED_LIBRARY => {:OSX => 'lib'}}
  OUTPUT_SUFFIX = {:EXECUTABLE => '.exe', :SHARED_LIBRARY => {:UNIX => '.so', :OSX => '.dylib'}}
  ADDITIONAL_COMMANDS_CONTENT = ['1', '2']
  class DummyCommands
    def calc(linker, bb)
      return ADDITIONAL_COMMANDS_CONTENT
    end
  end
  ADDITIONAL_COMMANDS = DummyCommands.new
  before(:each) do
    Cxxproject::Utils.cleanup_rake

    File.open(SOURCE_NAME, 'w') do |io|
      io.puts('// just for testing')
    end
    @lib1 = Cxxproject::StaticLibrary.new('lib1', true)
    @lib1.set_output_dir(OUTDIR)
    @lib1.set_project_dir('.')
    @lib1.set_sources([SOURCE_NAME])
    @lib1.complete_init
    @shared_lib = Cxxproject::SharedLibrary.new('shared_lib')
    @shared_lib.set_output_dir(OUTDIR)
    @shared_lib.set_project_dir('.')
    @shared_lib.set_sources([SOURCE_NAME])
    @shared_lib.complete_init
    @exe = Cxxproject::Executable.new('test')
    @exe.set_output_dir(OUTDIR)
    @exe.set_project_dir('.')
    @exe.set_sources([SOURCE_NAME])
    @exe.set_dependencies(['lib1'])
    @exe.complete_init
    @toolchain = double('Toolchain')
    @linker = double('Linker')
    @linker.stub(:[]).with(:COMMAND).and_return(COMMAND)
    @linker.stub(:[]).with(:MUST_FLAGS).and_return("#{MUSTFLAG1} #{MUSTFLAG2}")
    @linker.stub(:[]).with(:FLAGS).and_return([FLAGS])
    @linker.stub(:[]).with(:EXE_FLAG).and_return(EXE_FLAG)
    @linker.stub(:[]).with(:LIB_PREFIX_FLAGS).and_return(LIB_PREFIX)
    @linker.stub(:[]).with(:LIB_POSTFIX_FLAGS).and_return(LIB_POSTFIX)
    @linker.stub(:[]).with(:START_OF_WHOLE_ARCHIVE).and_return(START_OF_WHOLE_ARCHIVE)
    @linker.stub(:[]).with(:END_OF_WHOLE_ARCHIVE).and_return(END_OF_WHOLE_ARCHIVE)
    @linker.stub(:[]).with(:LIB_FLAG).and_return(LIB_FLAG)
    @linker.stub(:[]).with(:LIB_PATH_FLAG).and_return(LIB_PATH_FLAG)
    @linker.stub(:[]).with(:SHARED_FLAG).and_return(SHARED_FLAG)
    @linker.stub(:[]).with(:OUTPUT_PREFIX).and_return(OUTPUT_PREFIX)
    @linker.stub(:[]).with(:OUTPUT_SUFFIX).and_return(OUTPUT_SUFFIX)
    @linker.stub(:[]).with(:ADDITIONAL_COMMANDS).and_return({:OSX => ADDITIONAL_COMMANDS, :UNIX => ADDITIONAL_COMMANDS})
    @toolchain.stub(:[]).with(:LINKER).and_return(@linker)
    @shared_lib.set_tcs(@toolchain)
    @exe.set_tcs(@toolchain)
  end

  after(:each) do
    File.delete(SOURCE_NAME)
  end

  [:OSX, :UNIX].each do |os|
    it "should work for #{os}" do
      @toolchain.stub(:[]).with(:TARGET_OS).and_return(os)
      @exe.convert_to_rake
      @shared_lib.convert_to_rake
      @exe.calc_command_line.should eq([COMMAND, MUSTFLAG1, MUSTFLAG2, FLAGS, EXE_FLAG, 'out/test.exe', LIB_PREFIX, START_OF_WHOLE_ARCHIVE[os], @lib1.get_archive_name, END_OF_WHOLE_ARCHIVE[os], LIB_POSTFIX])
    end
  end

  it 'should work for shared libraries' do
    @toolchain.stub(:[]).with(:TARGET_OS).and_return(:OSX)
    @exe.convert_to_rake
    @shared_lib.convert_to_rake
    @shared_lib.calc_command_line.should eq([COMMAND, MUSTFLAG1, MUSTFLAG2, FLAGS, SHARED_FLAG, EXE_FLAG, 'out/libs/libshared_lib.dylib'] + ADDITIONAL_COMMANDS_CONTENT + [LIB_PREFIX, LIB_POSTFIX])
  end

  it 'should be possible to define an executable without sources' do
    exe = Cxxproject::Executable.new('1')
    exe.output_dir = 'out'
    exe.complete_init
    exe.create_object_file_tasks
  end

end
