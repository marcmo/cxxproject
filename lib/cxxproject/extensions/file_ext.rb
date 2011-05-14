class File

  @@oldRuby = RUBY_VERSION[0..2] == "1.8"

  def self.is_absolute?(filename)
    if @@oldRuby
      filename[0] == 47 or filename[1] == 58 # 47 = /, 58 = :
    else
      filename[0] == '/' or filename[1] == ':'
    end
  end

  # filename relative to nowRelToThisDir (if absolute, nowRelToThisDir can be nil)
  # return: filename which is relative to thenRelToThisDir
  def self.relFromTo(filename,nowRelToThisDir,thenRelToThisDirOrg = Dir.pwd)
	  
	    absFilename = filename
	    thenRelToThisDir = thenRelToThisDirOrg + "/"
	    
	    if not File.is_absolute?(filename)
	      absFilename = File.expand_path(nowRelToThisDir + "/" + filename)
	    end
	
		maxLength = thenRelToThisDir.length > absFilename.length ? absFilename.length : thenRelToThisDir.length
		
		lastEqDir = -1
		for i in 0..maxLength-1  
			break if thenRelToThisDir[i] != absFilename[i]
	    end
	    lastEqDir = thenRelToThisDir.rindex("/",i)
	    
	    if lastEqDir
	    	dotdot = thenRelToThisDir[lastEqDir+1..-1].split("/").length
	    	res = ""
	    	dotdot.times  { res << "../" }
	    	res << absFilename[lastEqDir+1..-1]
	    	return absFilename if res.length > absFilename.length # avoid something like "../../../../../../usr/local/lib"
	    	return res
	    else
	    	return absFilename
	    end
    
    
    
  end
  
end
