cxx_configuration do

  source_lib "testme",
    :sources => FileList['**/*.cpp'],
    :includes => ['include'],
    :dependencies => []

  custom "testcustom",
    :execute => lambda { puts "executing testcustom" },
    :dependencies => ["testme"]

  custom "testcustom2",
    :execute => lambda { puts "executing testcustom2" },
    :dependencies => ["testcustom"]

end
