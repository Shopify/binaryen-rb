# frozen_string_literal: true

require "test_helper"

module Binaryen
  class CommandTest < Minitest::Test
    def test_it_returns_a_readable_stdout_stream
      wasm_opt = Binaryen::Command.new("wasm-opt", timeout: 2)
      version_number = Binaryen::BINARYEN_VERSION.split("_").last
      result = wasm_opt.run("--version")

      assert_match(/wasm-opt version #{version_number}/, result.strip)
    end

    def test_it_accepts_stdin
      wasm_opt = Binaryen::Command.new("wasm-opt", timeout: 2)
      result = wasm_opt.run("-O4", stdin: "(module)")
      expected = "\x00asm"

      assert(result.start_with?(expected), "Expected #{result.inspect} to start with #{expected.inspect}")
    end

    def test_times_out_sanely_on_no_output
      attempts = 5

      begin
        timeout = 0.1
        sleep_command = Binaryen::Command.new("sleep", timeout: 0.1, ignore_missing: true)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        assert_raises(Timeout::Error) do
          sleep_command.run("5")
        end
        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        duration = end_time - start_time
        error_margin = timeout * 1.10

        assert(duration >= timeout, "should not time out early")
        assert(duration < error_margin, "timeout took too long")
      rescue Minitest::Assertion
        attempts -= 1
        retry if attempts > 0
        raise
      end
    end

    def test_times_out_sanely_on_reads
      attempts = 5

      begin
        timeout = 0.1
        yes_command = Binaryen::Command.new("yes", timeout: 0.1, ignore_missing: true)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        assert_raises(Timeout::Error) do
          yes_command.run
        end
        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        duration = end_time - start_time
        error_margin = timeout * 1.10

        assert(duration >= timeout, "should not time out early")
        assert(duration < error_margin, "timeout took too long")
      rescue Minitest::Assertion
        attempts -= 1
        retry if attempts > 0
        raise
      end
    end

    def test_times_out_sanely_on_blocking_writes
      attempts = 5
      stdin =  "y" * (64 * 1024 * 1024)

      begin
        timeout = 0.1
        slow_command = Binaryen::Command.new("ruby", ignore_missing: true, timeout: timeout)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        assert_raises(Timeout::Error) do
          slow_command.run("-e", "while STDIN.getc; sleep 0.01; end", stdin: stdin)
        end
        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        duration = end_time - start_time
        error_margin = timeout * 1.10

        assert(duration >= timeout, "should not time out early")
        assert(duration < error_margin, "timeout took too long")
      rescue Minitest::Assertion
        attempts -= 1
        retry if attempts > 0
        raise
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
