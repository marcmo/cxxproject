#include "lib2.h"
#include <iostream>
#include "help.h"

int main(int argc, char** args) {
  for (int i=0; i<argc; ++i) {
    std::cout << "arg " << i << ": " << args[i] << std::endl;
  }
  helpMe();
  lib2();
  std::cout << "hello world" << std::endl;
  return 0;
}
