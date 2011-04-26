$toolchainSettings = {}

# the following toolchains are provided by cxxproject
require 'cxxproject/toolchain/gcc'
require 'cxxproject/toolchain/diab'

class ProjectSettings
  attr_reader :projectDir, :outputDir, :name, :type
  attr_accessor :includeDirs, :libDirs, :libs, :libPaths, :userLibs 
  attr_accessor :sources, :objects, :linkerScript, :libsWithPath
  attr_accessor :toolchainSettings
  attr_accessor :makefiles
  attr_reader :includeDirsString, :definesString
  attr_accessor :deps
  attr_accessor :configFiles
  
  # projectDir must be absolute
  # outputDir relative to projectDir or absolute
  def initialize(projectName, projectDir, outputDir, type)
  	# for all projects
    @name = projectName
  	@projectDir = projectDir
  	@outputDir = outputDir
  	@includeDirs = []
  	@sources = []
  	@makefiles = {:BEGIN => [], :MID => [], :END => []}
  	@type = type # can be :Library, :Executable, :Empty

	# to be filled during building rake tasks
  	# @objects = "" ??
  	@includeDirsString = {:CPP => "", :C => "", :ASM => ""}
  	@definesString     = {:CPP => "", :C => "", :ASM => ""}
  	
  	# only for executable projects
  	@libs = []
  	@libPaths = []
  	@libsWithPath = []
  	@userLibs = []
  	@linkerScript = ""
  	
  	@toolchainSettings = nil # must be set before raking
  	
  	@configFiles = [] # dependency to these config files
  end

  def prepareBuild
  	[:CPP, :C, :ASM].each do |t|
  		@includeDirsString[t] = @includeDirs.uniq.map {|k| "#{@toolchainSettings[:COMPILER][t][:INCLUDE_PATH_FLAG]} #{k}" }.join(" ")
	  	@definesString[t] = @toolchainSettings[:COMPILER][t][:DEFINES].map {|k| "#{@toolchainSettings[:COMPILER][t][:DEFINE_FLAG]}#{k}" }.join(" ")
	end
  	@sources = @sources.inject([]) {|res, s| res << s if getSourceType(s); res}
  end
  
  def getSources(toolchainSettings, sourceType)
  	sources.keep_if {|v| not toolchainSettings[sourceType].include? File.extname(v) }
  end
  
  def getObjectName(source)
  	s = File.relFromTo(source,::Dir.pwd,projectDir)
    File.relFromTo(getOutputDir + "/" + s + ".o",projectDir)
  end

  def getSourceType(source)
  	ex = File.extname(source)
  	[:CPP, :C, :ASM].each do |t|
  		return t if toolchainSettings[:COMPILER][t][:SOURCE_FILE_ENDINGS].include?(ex)
  	end
  	nil
  end
  
  def getArchiveName()
  	File.relFromTo(projectDir + "/" + outputDir + "/lib" + name + ".a",projectDir)
  end
  
  def getExecutableName()
  	File.relFromTo(projectDir + "/" + outputDir + "/" + name + @toolchainSettings[:LINKER][:OUTPUT_ENDING],projectDir)
  end  

  def getOutputDir()
  	File.relFromTo(projectDir + "/" + outputDir,projectDir)
  end  

  	
end

