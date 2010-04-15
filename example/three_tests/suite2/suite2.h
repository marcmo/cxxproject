#ifndef suite2_h_
#define suite2_h_

#include <cppunit/TestCase.h>
#include <cppunit/extensions/HelperMacros.h>

class Suite2 : public CppUnit::TestFixture {

public:

  void setUp() {
  }


  void tearDown() {
  }

  void test2() {
    CPPUNIT_ASSERT_MESSAGE( "hat auch geklappt", true );
  }

  CPPUNIT_TEST_SUITE( Suite2 );
  CPPUNIT_TEST( test2 );
  CPPUNIT_TEST_SUITE_END();

};

#endif
