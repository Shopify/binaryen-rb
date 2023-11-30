# frozen_string_literal: true

require "binaryen"

wasm_code = <<~WASM
  (module
    (func $one (result i32)
      (i32.const 1)
    )

    (func $two (result i32)
      (i32.const 2)
    )

    (export "one" (func $one))
    (export "two" (func $two))
  )
WASM

wasm_split = Binaryen::Command.new("wasm-split", timeout: 2)
result = wasm_split.run("-", stdin: wasm_code, stderr: $stderr)
puts(result.read)
# exit(result.read.start_with?("\x00asm"))
