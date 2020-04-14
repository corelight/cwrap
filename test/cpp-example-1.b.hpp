#ifdef __cplusplus
struct my_struct {
   my_struct(const char *f               ) { f_ = f; params_printf("arg1=%s\n"         , f_   ); append_printf(  "constructing my_struct\n"           ); }
   my_struct(const char *f, const char *b) { f_ = f; params_printf("arg1=%s, arg2=%s\n", f_, b); append_printf(  "constructing my_struct\n"           ); }
  ~my_struct(                            ) {                                                     append_printf("deconstructing my_struct; f_=%s\n", f_); }
  const char *f_;
};

template <class my_type>
my_type get_max (my_type a, my_type b) { params_printf("a=%d, b=%d\n", a, b); my_type r = (a > b) ? a : b; result_printf("r=%d\n", r); return r; }
#endif
