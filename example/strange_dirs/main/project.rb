cxx_configuration do
  exe 'main',
    :sources => Dir.glob('*.cpp'),
    :dependencies => 'lazy'
end
