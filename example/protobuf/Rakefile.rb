$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")

require 'yaml'

PROTOBUF_VERSION='2.4.1'
PROTOBUF_BASE="protobuf-#{PROTOBUF_VERSION}"
PROTOBUF_ARCHIVE="#{PROTOBUF_BASE}.tar.gz"
PROTOBUF_DOWNLOAD="tmp/#{PROTOBUF_ARCHIVE}"

directory 'tmp'

desc "download protobuf #{PROTOBUF_VERSION}"
file PROTOBUF_DOWNLOAD => 'tmp' do
  cd 'tmp' do
    command = "wget http://protobuf.googlecode.com/files/#{PROTOBUF_ARCHIVE}"
    sh command
    sleep(2)
  end
end

PROTOBUF_TMP = File.join(PROTOBUF_BASE, 'tmp')
PROTOC = File.join(PROTOBUF_TMP, 'src', 'protoc')
PROTOBUF_CONFIG_H=File.join(PROTOBUF_TMP, 'config.h')

PROTOBUF_LITE_SOURCES=YAML.load(IO.read('protobuf.files')).map{ | i | File.join(PROTOBUF_BASE, 'src', i)}
file PROTOBUF_LITE_SOURCES[0] => PROTOBUF_DOWNLOAD do |t|
  command = "tar xf #{PROTOBUF_DOWNLOAD}"
  sh command
  command = "find #{PROTOBUF_BASE}/ -exec touch {} \\;"
  sh command
  sleep(2) # wait for file timestamps to matter
end

directory PROTOBUF_TMP
desc 'configure protobuf'
file PROTOBUF_CONFIG_H => PROTOBUF_LITE_SOURCES + [PROTOBUF_TMP] do
  cd PROTOBUF_TMP do
    command = '../configure'
    sh command
  end
end

desc 'build protoc'
file PROTOC => [PROTOBUF_CONFIG_H] do
  cd PROTOBUF_TMP do
    command = 'make'
    sh command
  end
end

require 'cxxproject'

GEN_FOLDER = File.join('addressbook', 'gen')
CLEAN.include('GEN_FOLDER')

directory GEN_FOLDER
['addressbook.pb.h', 'addressbook.pb.cc'].each do |f|
  desc 'protoc addressbook.proto'
  file File.join(GEN_FOLDER, 'addressbook', f) => [File.join('addressbook', 'addressbook.proto'), GEN_FOLDER, PROTOC] do
    command = "#{PROTOC} --cpp_out=#{GEN_FOLDER} #{File.join('addressbook', 'addressbook.proto')}"
    sh command
  end
end

CxxProject2Rake.new(FileList['**/*project.rb'] , "build", "gcc", ".")


CLEAN.include('tmp')
CLEAN.include(PROTOBUF_BASE)
CLEAN.include(GEN_FOLDER)
