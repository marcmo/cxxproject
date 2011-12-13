cxx_configuration do

  source_lib "testme",
    :sources => FileList['**/*.cpp'],
    :includes => ['include'],
    :dependencies => []

  # using lambdas
  custom "testcustom",
    :execute => lambda { puts "executing testcustom" },
    :dependencies => ["testme"]

  def foo
    puts "foo for testcustom2"
  end

  # using methods
  custom "testcustom2",
    :execute => method(:foo),
    :dependencies => ["testcustom"]

  # using new lambda syntax
  custom "testcustom3",
    :execute => -> { puts "executing testcustom3" },
    :dependencies => ["testcustom2"]

end
