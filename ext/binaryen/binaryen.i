%module "binaryen::ffi"
%{
#include "binaryen-c.h"
%}

%init {
  const char *classes[] = {
      "TYPE_p_BinaryenModule",
      "TYPE_p_uintptr_t",
      "TYPE_p_BinaryenExpression",
      "TYPE_p_int32_t",
      "TYPE_p_BinaryenFunction"
  };

  int num_classes = sizeof(classes) / sizeof(classes[0]);

  for (int i = 0; i < num_classes; i++) {
      VALUE klass = rb_const_get(_mSWIG, rb_intern(classes[i]));
      rb_undef_alloc_func(klass);
  }
}

%typemap(in) BinaryenIndex {
  if (TYPE($input) != T_FIXNUM) {
    SWIG_exception_fail(SWIG_ArgError(SWIG_ERROR), "Expected a Fixnum for argument $argnum");
  }
  $1 = (BinaryenIndex)NUM2UINT($input);
}

%typemap(in) (BinaryenType* valueTypes, BinaryenIndex numTypes) {
  if (TYPE($input) != T_ARRAY) {
    SWIG_exception_fail(SWIG_ArgError(SWIG_ERROR), "Expected an Array for argument $argnum");
  }

  $2 = (BinaryenIndex) RARRAY_LEN($input);
  $1 = ALLOC_N(BinaryenType, $2);

  for (BinaryenIndex i = 0; i < $2; i++) {
    VALUE elem = rb_ary_entry($input, i);

    if (!rb_obj_is_kind_of(elem, rb_cObject)) {
      SWIG_exception_fail(SWIG_ArgError(SWIG_ERROR), "Expected a SWIG wrapped object for element in argument $argnum");
    }

    $1[i] = *(BinaryenType*)DATA_PTR(elem);
  }
}

%typemap(freearg) (BinaryenType* types) {
  xfree($1);
}

%extend BinaryenModuleAllocateAndWriteResult {
  VALUE to_s() {
    return rb_str_new((char*)$self->binary, $self->binaryBytes);
  }
}

%header %{
  static void free_BinaryenModuleAllocateAndWriteResultCustom(void* ptr) {
    BinaryenModuleAllocateAndWriteResult* result = (BinaryenModuleAllocateAndWriteResult*) ptr;

    if (result->binary) {
      free(result->binary);
    }

    if (result->sourceMap) {
      free(result->sourceMap);
    }

    free((char *) result);
  }
%}

%freefunc BinaryenModuleAllocateAndWriteResult "free_BinaryenModuleAllocateAndWriteResultCustom";

%include "binaryen-c.h"
