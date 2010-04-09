#ifndef test1_h_
#define test1_h_

#include <cppunit/TestCase.h>
#include <cppunit/extensions/HelperMacros.h>

class Test1 : public CppUnit::TestFixture {

public:

  void setUp() {
  }


  void tearDown() {
  }

  void test1() {
    CPPUNIT_ASSERT_MESSAGE( "hat geklappt", true );
  }

  CPPUNIT_TEST_SUITE( Test1 );
  CPPUNIT_TEST( test1 );
  CPPUNIT_TEST_SUITE_END();

};

#endif
