#include "lib2.h"

#include <iostream>
#include <math.h>
#include "lib1.h"
#include <dlfcn.h>
#include <zlib.h>

void lib2() {
  std::cout << "lib2" << std::endl;
  lib1();
  std::cout << sin(5) << std::endl;
  void* help = dlopen("test", RTLD_LAZY);
  std::cout << (long)help << std::endl;
  Bytef b = 0;
  uLong res = crc32(0, &b, 1);
}
