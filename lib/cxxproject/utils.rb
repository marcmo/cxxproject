module OS
  def OS.windows?
    (RUBY_PLATFORM =~ /cygwin|mswin|mingw|bccwin|wince|emx/) != nil
  end
  def OS.mac?
    (RUBY_PLATFORM =~ /darwin/) != nil
  end
  def OS.unix?
    !OS.windows?
  end
  def OS.linux?
    OS.unix? and not OS.mac?
  end
end
