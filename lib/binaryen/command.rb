# frozen_string_literal: true

require "timeout"
require "posix/spawn"

module Binaryen
  # Wrapper around a binaryen executable command with a timeout and streaming IO.
  #
  # @example Running wasm-opt
  #
  #   ```ruby
  #   command = Binaryen::Command.new("wasm-opt", timeout: 10)
  #   optimized_wasm = command.run("-O4", stdin: "(module)")
  #   ```
  class Command
    DEFAULT_ARGS_FOR_COMMAND = {
      "wasm-opt" => ["--output=-"],
    }.freeze

    class TimeoutChecker
      def initialize(end_time:, pid:)
        @end_time = end_time
        @pid = pid
      end

      def check!
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if now >= @end_time
          Process.kill("KILL", @pid)
          raise Timeout::Error, "Command timed out"
        end
        remaining_time = @end_time - now
        remaining_time
      end
    end

    def initialize(cmd, timeout: 10, ignore_missing: false)
      @cmd = command_path(cmd, ignore_missing) || raise(ArgumentError, "command not found: #{cmd}")
      @timeout = timeout
      @default_args = DEFAULT_ARGS_FOR_COMMAND.fetch(cmd, [])
    end

    def run(*arguments, stdin: nil, stderr: File::NULL)
      args = build_arguments(*arguments)
      child = POSIX::Spawn::Child.new(@cmd, *args, input: stdin, timeout: @timeout)
      if child.status && !child.status.success?
        err_io = stderr.is_a?(String) ? File.open(stderr, "w") : stderr
        err_io.binmode
        err_io.write(child.err)
        err_io.rewind
        raise NonZeroExitStatus, "command exited with non-zero status: #{child.status}"
      end

      child.out
    rescue POSIX::Spawn::TimeoutExceeded => e
      raise Timeout::Error, e.message
    end

    private

    def build_arguments(*arguments)
      arguments + @default_args
    end

    def command_path(cmd, ignore_missing)
      Dir[File.join(Binaryen.bindir, cmd)].first || (ignore_missing && cmd)
    end
  end
end
