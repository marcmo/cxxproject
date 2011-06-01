cxx_configuration do
  deps = [BinaryLibrary.new('z'), BinaryLibrary.new('pthread')]

  source_lib 'protobuf',
    :sources => PROTOBUF_LITE_SOURCES.delete_if{ |i| i.index('.h') },
    :includes => [File.join(PROTOBUF_BASE, 'src'), File.join(PROTOBUF_BASE, 'tmp')],
    :dependencies => deps,
    :file_dependencies => [PROTOBUF_CONFIG_H]
end
