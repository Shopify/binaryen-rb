# frozen_string_literal: true

require "test_helper"

module Binaryen
  class CommandTest < Minitest::Test
    def test_it_returns_a_readable_stdout_stream
      wasm_opt = Binaryen::Command.new("wasm-opt", timeout: 2)
      version_number = Binaryen::BINARYEN_VERSION.split("_").last
      result = wasm_opt.run("--version")

      assert_match(/wasm-opt version #{version_number}/, result.read.strip)
    end

    def test_it_accepts_stdin
      wasm_opt = Binaryen::Command.new("wasm-opt", timeout: 2)
      result = wasm_opt.run("-O4", stdin: "(module)")

      assert_equal("asm\x01", result.read.strip)
    end

    def test_times_out_sanely
      sleep_command = Binaryen::Command.new("sleep", timeout: 0.1, ignore_missing: true)

      assert_raises(Timeout::Error) do
        sleep_command.run("5")
      end
    end

    def test_it_raises_an_error_with_a_reasonable_message_if_the_command_is_not_found
      missing_command = Binaryen::Command.new("wasm-opt")

      err = assert_raises(Binaryen::NonZeroExitStatus) do
        missing_command.run("dfasdfasdfasdfsadf")
      end

      assert_match(/^command exited with status 1:/, err.message)
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
