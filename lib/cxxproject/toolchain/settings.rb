$toolchainSettings = {}

# the following toolchains are provided by cxxproject
require 'cxxproject/toolchain/gcc'
require 'cxxproject/toolchain/diab'

# projectDir relToThisDir vice versa when reading dep files!
def makeFilename(filename,projectDir,relToThisDir = nil)
	if relToThisDir.nil?
		relToThisDir = Dir.pwd
	end

	fpath = Pathname.new(filename)
	res = filename
	
	if not fpath.absolute?
		res = File.expand_path(projectDir+"/"+filename)
	end
	
	begin
		res = Pathname.new(res).relative_path_from(Pathname.new(relToThisDir)).to_s
	rescue # not the same dir (well, Pathname is case sensitive on Windows as well...)
		res
	end		
end


class ProjectSettings
  attr_reader :projectDir, :outputDir, :name, :type
  attr_accessor :includeDirs, :libDirs, :libs, :libPaths, :userLibs 
  attr_accessor :sources, :objects, :linkerScript, :libsWithPath
  attr_accessor :toolchainSettings
  attr_accessor :makefiles
  attr_reader :includeDirsString, :definesString
  attr_accessor :deps
  
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
  	s = makeFilename(source,::Dir.pwd,projectDir)
    makeFilename(getOutputDir + "/" + s + ".o",projectDir)
  end

  def getSourceType(source)
  	ex = File.extname(source)
  	[:CPP, :C, :ASM].each do |t|
  		return t if toolchainSettings[:COMPILER][t][:SOURCE_FILE_ENDINGS].include?(ex)
  	end
  	nil
  end
  
  def getArchiveName()
  	makeFilename(projectDir + "/" + outputDir + "/lib" + name + ".a",projectDir)
  end
  
  def getExecutableName()
  	makeFilename(projectDir + "/" + outputDir + "/" + name + @toolchainSettings[:LINKER][:OUTPUT_ENDING],projectDir)
  end  

  def getOutputDir()
  	makeFilename(projectDir + "/" + outputDir,projectDir)
  end  

  	
end

