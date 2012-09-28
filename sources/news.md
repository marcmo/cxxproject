
## New features

### since 0.6.30

* each building block is now addressable using it's name, e.g.

project.rb

    source_lib 'a',
      :sources => FileList['**/*.cpp'],
      :includes => ['include']

Rakefile.rb

    task :do_a_before => 'a'


