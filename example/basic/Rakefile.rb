require 'rubydsl/rubydsl'

projects_to_rake(['basic/project.rb','lib1/project.rb','lib2/project.rb'] , "build", 'gcc', ".")
# CxxProject2Rake.new(['basic/project.rb','lib1/project.rb','lib2/project.rb'] , "build", "clang", ".") do
#   p "calling block..."
#   unittest_flags = {
#     :DEFINES => ['UNIT_TEST',"OUR_STUFF"],
#     :FLAGS => "-O0 -g3 -Wall"
#   }
#   Provider.modify_cpp_compiler("clang", unittest_flags)
# end
