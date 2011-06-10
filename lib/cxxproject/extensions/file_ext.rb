class File

  SLASH = '/'

  def self.old_ruby?
    RUBY_VERSION[0..2] == "1.8"
  end

  def self.is_absolute?(filename)
    if old_ruby?
      filename[0] == 47 or filename[1] == 58 # 47 = /, 58 = :
    else
      filename[0] == SLASH or filename[1] == ':'
    end
  end

  # filename relative to nowRelToThisDir (if absolute, nowRelToThisDir can be nil)
  # return: filename which is relative to thenRelToThisDir
  def self.relFromTo(filename,nowRelToThisDir,thenRelToThisDirOrg = Dir.pwd)
    absFilename = filename
    thenRelToThisDir = thenRelToThisDirOrg + SLASH

    if not File.is_absolute?(filename)
      absFilename = File.expand_path(nowRelToThisDir + SLASH + filename)
    end

    i = find_last_equal_character(thenRelToThisDir, absFilename)
    lastEqDir = thenRelToThisDir.rindex(SLASH,i)

    if lastEqDir
      dotdot = thenRelToThisDir[lastEqDir+1..-1].split(SLASH).length
      res = ("..#{SLASH}" * dotdot) + absFilename[lastEqDir+1..-1]
      return [absFilename, res].min_by{|x|x.length}
    else
      return absFilename
    end
  end

  def self.find_last_equal_character(s1, s2)
    max = [s1.length, s2.length].min
    i = 0
    while i < max
      break if s1[i] != s2[i]
      i += 1
    end
    return i
  end

end
