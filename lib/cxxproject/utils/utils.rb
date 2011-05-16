# Simple helper query the operating system we are running in
module OS

  # Is it windows
  def OS.windows?
    (RUBY_PLATFORM =~ /cygwin|mswin|mingw|bccwin|wince|emx/) != nil
  end

  # Is it osx
  def OS.mac?
    (RUBY_PLATFORM =~ /darwin/) != nil
  end

  # Is it kind of unix
  def OS.unix?
    !OS.windows?
  end

  # Is it linux
  def OS.linux?
    OS.unix? and not OS.mac?
  end

end

module Utils

def self.deep_copy(x)
  Marshal.load(Marshal.dump(x))
end


end