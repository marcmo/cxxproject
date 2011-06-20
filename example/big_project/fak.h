template <long N> class fib {
  public:
    static const long value = fib<N-1>::value + fib<N-1>::value;
};

template <> class fib<1> {
  public:
    static const long value = 1;
};
