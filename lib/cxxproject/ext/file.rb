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

  def self.find_last_equal_character(s1, s2)
    max = [s1.length, s2.length].min
    i = 0
    while i < max
      break if s1[i] != s2[i]
      i += 1
    end
    return i
  end

  def self.relFromToProject(from,toOrg)
    return nil if from.nil? or toOrg.nil?
    return "" if from==toOrg
    to = toOrg + "/"
    i = find_last_equal_character(from, to)
    lastEqDir = to.rindex('/',i)
    return nil if not lastEqDir
    
    beforeEq = from[lastEqDir+1..-1]
    afterEq = to[lastEqDir+1..-1]
    
    return afterEq if not beforeEq
    
    splitted = beforeEq.split('/')
    return nil if not splitted
    
    ("../" * splitted.length) + afterEq
  end
  
  def self.addPrefix(prefix, file)
    if is_absolute?(file)
      file
    else
      prefix + file
    end
  end

end
