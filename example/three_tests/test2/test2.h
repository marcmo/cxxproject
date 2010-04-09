#ifndef test2_h_
#define test2_h_

#include <cppunit/TestCase.h>
#include <cppunit/extensions/HelperMacros.h>

class Test2 : public CppUnit::TestFixture {

public:

  void setUp() {
  }


  void tearDown() {
  }

  void test2() {
    CPPUNIT_ASSERT_MESSAGE( "hat nicht geklappt", false );
  }

  CPPUNIT_TEST_SUITE( Test2 );
  CPPUNIT_TEST( test2 );
  CPPUNIT_TEST_SUITE_END();

};

#endif
