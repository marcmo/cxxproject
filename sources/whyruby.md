## Why Ruby?

Ruby makes for a nice syntax of the project configurations and gives you the power of a first-class scripting language for any additional things you want to achieve using cxxproject.
Of course, EDSLs suffer the drawback that they can be a little awkward to use for non-programmers... but since cxxproject is aimed at programmers that is not an issue for us :)

and...not to forget: *rake*

rake provides a simple yet very powerful dependency system that we use extensively.
All the building blocks that make up the applications that we want to build can have dependencies to either each other or any other files.
rake has built in support for describing dependency based tasks that will be executeded when they are invoked...an ideal starting point for us.

example rake task:

    task :rebuild => :clean do
      # execute some build stuff
    end



