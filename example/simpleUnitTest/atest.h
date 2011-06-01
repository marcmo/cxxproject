#include "cppunit/extensions/HelperMacros.h"

class ATest : public CppUnit::TestFixture {
CPPUNIT_TEST_SUITE( ATest );
CPPUNIT_TEST( test1 );
CPPUNIT_TEST( test2 );
CPPUNIT_TEST_SUITE_END();
 public:
 void test1();
 void test2();
};
