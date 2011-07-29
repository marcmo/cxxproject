require 'cxxproject/utils/utils'

class File

  SLASH = '/'

  def self.is_absolute?(filename)
    if Cxxproject::Utils.old_ruby?
      filename[0] == 47 or filename[1] == 58 # 47 = /, 58 = :
    else
      filename[0] == SLASH or filename[1] == ':'
    end
  end

  def self.rel_from_to_project(from,to)
    return nil if from.nil? or to.nil?
    
	toSplitted = to.split('/')
	fromSplitted = from.split('/')
	
	max = [toSplitted.length, fromSplitted.length].min
	
	return nil if max < 1
	
	i = 0
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
	
	res.join('/')+"/"
  end

  
  def self.add_prefix(prefix, file)
    if not prefix or is_absolute?(file)
      file
    else
      prefix + file
    end
  end

end
