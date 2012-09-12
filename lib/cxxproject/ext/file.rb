require 'cxxproject/utils/utils'

class File

  SLASH = '/'

  def self.is_absolute?(filename)
    filename[0] == SLASH or filename[1] == ':'
  end

  def self.rel_from_to_project(from,to,endWithSlash = true)
    return nil if from.nil? or to.nil?

    toSplitted = to.split('/')
    fromSplitted = from.split('/')
    max = [toSplitted.length, fromSplitted.length].min
    return nil if max < 1

    i = 0
    # path letter in windows may be case different
    if toSplitted[0].length > 1 and fromSplitted[0].length > 1
      i = 1  if toSplitted[0][1] == ':' and fromSplitted[0][1] == ':' and toSplitted[0].swapcase[0] == fromSplitted[0][0]
    end
    while i < max
      break if toSplitted[i] != fromSplitted[i]
      i += 1
    end
    j = i
    res = []
    while i < fromSplitted.length
      res << ".."
      i += 1
    end

    while j < toSplitted.length
      res << toSplitted[j]
      j += 1
    end

    if res.length == 0
      return ""
    end

    res = res.join('/')
    res += "/" if endWithSlash
    res
  end

  def self.add_prefix(prefix, file)
    if not prefix or is_absolute?(file)
      file
    else
      prefix + file
    end
  end

end
