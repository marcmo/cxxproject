class File

  # filename relative to nowRelToThisDir (if absolute, nowRelToThisDir can be nil)
  # return: filename which is relative to thenRelToThisDir
  def self.relFromTo(filename,nowRelToThisDir,thenRelToThisDir = Dir.pwd)
    res = filename
    if not Pathname.new(filename).absolute?
      res = File.expand_path(nowRelToThisDir+"/"+filename)
    end

    begin
      res = Pathname.new(res).relative_path_from(Pathname.new(thenRelToThisDir)).to_s
    rescue # not the same dir (well, Pathname is case sensitive on Windows as well...)
      res
    end
  end

end
