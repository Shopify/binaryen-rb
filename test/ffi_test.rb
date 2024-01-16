# frozen_string_literal: true

require "test_helper"

module Binaryen
  class FfiTest < Minitest::Test
    include Ffi

    def test_creating_basic_module_with_binaryen
      mod = BinaryenModuleCreate()
      params = BinaryenTypeCreate([BinaryenTypeInt32(), BinaryenTypeInt32()])
      results = BinaryenTypeInt32()
      x = BinaryenLocalGet(mod, 0, BinaryenTypeInt32())
      y = BinaryenLocalGet(mod, 1, BinaryenTypeInt32())
      add = BinaryenBinary(mod, BinaryenAddInt32(), x, y)
      BinaryenAddFunction(mod, "adder", params, results, nil, 0, add)

      write_result = BinaryenModuleAllocateAndWrite(mod, nil)
      text_result = BinaryenModuleAllocateAndWriteText(mod)

      assert(write_result.to_s.start_with?("\x00asm"))
      assert_equal(<<~WAT, text_result)
        (module
         (type $0 (func (param i32 i32) (result i32)))
         (func $adder (param $0 i32) (param $1 i32) (result i32)
          (i32.add
           (local.get $0)
           (local.get $1)
          )
         )
        )
      WAT
    end
  end
end
