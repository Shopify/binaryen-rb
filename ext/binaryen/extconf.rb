# frozen_string_literal: true

require "mkmf"
require_relative "../../lib/binaryen"

dir_config("binaryen", Binaryen.includedir, Binaryen.libdir)

append_cppflags("-Wno-deprecated-declarations")
append_cppflags("-Wno-missing-noreturn")

if find_library("binaryen", "BinaryenModuleAllocateAndWrite")
  append_ldflags("-Wl,-rpath,#{Binaryen.libdir}")
else
  append_ldflags("-Wl,-Bstatic -lbinaryen -Wl,-Bdynamic")
end

create_makefile("binaryen/ffi")
