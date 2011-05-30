# cxxproject


see documentation page: [cxxproject](http://marcmo.github.com/cxxproject)

### Tests

There are three kinds of tests:

* [spec files](https://github.com/marcmo/cxxproject/tree/master/spec)
* roodi
* the [examples](https://github.com/marcmo/cxxproject/tree/master/example): use rake -T to find out about the ways to use

### Prerequisites

gems: [rspec](http://rspec.info/), [roodi](http://roodi.rubyforge.org) (optional)
libs: cppunit (only required for some examples)

### Installation

    rake install

should install the freshly built gem (if you need sudo, please install the package by hand via rake package; sudo gem install pkg/...)

    cd examples; rake 

should compile all examples and let the executables run


