STDOUT.sync = true
STDERR.sync = true
$stdoutMutex = Mutex.new
module ThreadOut
  
  $stdoutMutex = Mutex.new
  def self.write(stuff)
  	if Thread.current[:nostdout]
  	  return
  	end
  
  	$stdoutMutex.synchronize { 
  		STDOUT.write stuff
  	}
  end

  def self.puts(stuff)
  	self.write(stuff)
  end
end

$stdout = ThreadOut
$stderr = ThreadOut
