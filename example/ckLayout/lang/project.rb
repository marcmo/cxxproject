cxx_configuration "" do
  files = FileList['**/*.cpp']
  source_lib "io",
    :sources => files
end
        
