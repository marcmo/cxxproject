require 'rake/clean'

CLEAN.include('main.css','index.html','docs')
OUTDIR="docs"
SRC = FileList["sources/*.md"]
IMAGES = FileList["images/**/*.*"]
Header = "sources/head.html" 
Footer = "sources/foot.html"

directory OUTDIR

def outname(fn)
  File.join(OUTDIR, File.basename(fn).ext('html'))
end

HTML = SRC.collect { |fn| outname fn }

desc "build documentation site"
task :site => ["index.html","main.css"] + HTML
task :default => :site

file Header => "index.html" do
  sh "jade < sources/menu.jade > #{Header}"
  begin
    f = File.open(Header)
    content = f.gets.gsub(/<\/div><\/body><\/html>$/,'<div id="content">')
    f2 = File.open(Header,'w')
    f2.write(content)
  ensure
    f.close
    f2.close
  end
end

file "index.html" => ["sources/index.jade"] + IMAGES do
  sh "jade < sources/index.jade > index.html"
end

file "main.css" => "sources/main.styl" do
  sh "stylus < sources/main.styl > main.css"
end

SRC.each do |src|
  outfile = outname(src)
  file outfile => [src, OUTDIR, Header, Footer] do
    sh "markdown < #{src} | cat #{Header} - #{Footer} > #{outfile}"
  end
end


