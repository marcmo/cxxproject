module Cxxproject
  class StringUtils
    def self.splitString(str, chunkSize, delim, delimShift = -1)
      res = []
      s = str
      oldPos = 0
      while s.length > chunkSize + oldPos
        pos = s.rindex(delim,oldPos+chunkSize)
        res << s[oldPos..pos+delimShift]
        oldPos = pos+delim.length
      end
      res << s[oldPos..-1]
      res
    end  
  end
end
