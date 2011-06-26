module Cxxproject
  module Utils
    define_stats = lambda do
      require 'haml'

      def count_sources(bbs)
        return bbs.inject(0) do |memo, bb|
          memo += bb.sources.size if bb.kind_of?(HasSources)
          memo
        end
      end
      def print_sources(io, bbs, indent)
        io.puts(indent + '%div.details')
        bbs.each do |bb|
          if bb.kind_of?(HasSources)
            io.puts(indent + "  %p Sources of #{bb.name}: #{bb.sources.size}")
            io.puts(indent + '  %ul')
            bb.sources.each do |s|
              io.puts(indent + "    %li #{s}")
            end
          end
        end
      end

      def handle_exe(io, bb, indent)
        if bb.kind_of?(Executable)
          io.puts(indent + "%h1")
          bbs = bb.all_dependencies.map{|name|ALL_BUILDING_BLOCKS[name]}
          io.puts(indent + "  %p.details_toggle Executable '#{bb.name}' total sources: #{count_sources(bbs)}")
          print_sources(io, bbs, indent + ' '*2)
        end
      end

      directory 'build'

      desc 'print building block stats'
      task :stats => 'build' do
        io = StringIO.new
        io.puts('%html')
        io.puts('  %head')
        io.puts('    %title Some Stats')
        io.puts('    %script{ :type => "text/javascript", :src=>"http://ajax.googleapis.com/ajax/libs/jquery/1.5/jquery.min.js"}')
        io.puts('    :javascript')
        io.puts('      $(document).ready(function() {$("div.details").hide();$("p.details_toggle").click(function() {$(this).siblings().last().toggle();});});')
        io.puts('  %body')
        res = ALL_BUILDING_BLOCKS.inject(io) do |memo, pair|
          key, bb = pair
          handle_exe(memo, bb, ' '*4)
          memo
        end
        engine = Haml::Engine.new(res.string)
        File.open(File.join('build','stats.out.html'), 'w') do |out|
          out.puts(engine.render)
        end
      end
    end

    optional_package(define_stats, nil)
  end
end
