cxx_configuration do

  static_lib 'addressbook_pb_api',
    :sources => ['gen/addressbook/addressbook.pb.cc'],
    :includes => ['gen'],
    :dependencies => ['protobuf']

  exe 'addressbook_write',
    :sources => ['addressbook_write.cc'],
    :dependencies => ['addressbook_pb_api']

  exe 'addressbook_read',
    :sources => ['addressbook_read.cc'],
    :dependencies => ['addressbook_pb_api']

end
