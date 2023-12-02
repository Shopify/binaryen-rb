# frozen_string_literal: true

require "binaryen"

wasm_code = <<~WASM
  (module
    (export "thing" (func $thing))

    (func $thing (; 0 ;) (param $0 i32) (result i32)
      (i32.add
        (local.get $0)
        (i32.add
          (i32.const 40)
          (i32.const 2)
        )
      )
    )
  )
WASM

wasm_opt = Binaryen::Command.new("wasm-opt", timeout: 2)
puts(wasm_opt.run("--emit-text", "-O4", "--debug", stdin: wasm_code, stderr: $stderr))
