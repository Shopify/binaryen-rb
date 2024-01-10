# frozen_string_literal: true

require "test_helper"

module Binaryen
  class CommandTest < Minitest::Test
    def test_it_returns_a_readable_stdout_stream
      wasm_opt = Binaryen::Command.new("wasm-opt", timeout: 2)
      Binaryen::BINARYEN_VERSION.split("_").last
      result = wasm_opt.run(stdin: "(module)")

      assert(result.start_with?("\x00asm"), "Expected #{result.inspect} to start with \\x00asm")
    end

    def test_raises_when_output_exceeds_maximum
      cmd = Binaryen::Command.new("wasm-opt", timeout: 30, max_output_size: 1)
      assert_raises(Binaryen::MaximumOutputExceeded) do
        cmd.run(stdin: "(module)")
      end
    end

    def test_it_accepts_stdin
      wasm_opt = Binaryen::Command.new("wasm-opt", timeout: 2)
      result = wasm_opt.run("-O4", stdin: "(module)")
      expected = "\x00asm"

      assert(result.start_with?(expected), "Expected #{result.inspect} to start with #{expected.inspect}")
    end

    def test_times_out_sanely_on_reads
      command = Binaryen::Command.new("wasm-opt", timeout: 0.0001)
      code = <<~WASM
        (module
          #{(1..100000).map { |i| "(func (export \"f#{i}\") (result i32) (i32.const #{i}))" }.join("\n")}
        )
      WASM

      assert_raises(Timeout::Error) do
        command.run("-O4", stdin: code)
      end
    end

    def test_it_raises_an_error_with_a_reasonable_message_if_the_command_is_not_found
      missing_command = Binaryen::Command.new("wasm-opt")

      err = assert_raises(Binaryen::NonZeroExitStatus) do
        missing_command.run("dfasdfasdfasdfsadf")
      end

      assert_match(/^command exited with status 1/, err.message)
    end

    def test_it_can_redirect_stderr
      missing_command = Binaryen::Command.new("wasm-opt", timeout: 2)
      stderr = Tempfile.new("stderr")

      assert_raises(Binaryen::NonZeroExitStatus) do
        missing_command.run("dfasdfasdfasdfsadf", stderr: stderr)
      end

      stderr.rewind
      assert_equal("Fatal: Failed opening 'dfasdfasdfasdfsadf'\n", stderr.read)
    ensure
      stderr.close
      stderr.unlink
    end
  end
end
