module ThreadOut

  def self.write(stuff)
    if Thread.current[:stdout] then
      Thread.current[:stdout].write stuff
    else
      STDOUT.write stuff
    end
  end

  def self.puts(stuff)
    if Thread.current[:stdout] then
      Thread.current[:stdout].puts stuff
    else
      STDOUT.puts stuff
    end
  end

end

