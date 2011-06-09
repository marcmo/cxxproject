template <long N> class fakultaet {
  public:
    static const long value = N * fakultaet<N - 1>::value;
};

template <> class fakultaet<1> {
  public:
    static const long value = 1;
};
