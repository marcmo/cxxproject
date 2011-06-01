#include "atest.h"

CPPUNIT_TEST_SUITE_REGISTRATION(ATest);

void ATest::test1()  {
  CPPUNIT_ASSERT(1 == 1);
}
int f1() {
  return 1;
}
int f2() {
  return 2;
}
void ATest::test2()  {
  CPPUNIT_ASSERT_EQUAL(f1(), f2());
}
