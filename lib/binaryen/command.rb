# frozen_string_literal: true

require "English"
require "shellwords"
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
    include POSIX::Spawn

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

    def run(*arguments, stdin: nil, stderr: nil)
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) + @timeout
      command = build_command(*arguments)
      pid, iwr, ord, erd = popen4(*command)
      timeout_checker = TimeoutChecker.new(end_time: end_time, pid: pid)

      write_to_pipe(iwr, stdin, timeout_checker) if stdin
      if stderr
        err_output = read_from_pipe(erd, timeout_checker)
        write_to_pipe(stderr, err_output, timeout_checker, close_write: false)
      end
      output = read_from_pipe(ord, timeout_checker)
      wait_or_kill(pid, timeout_checker, erd, stderr)

      output
    end

    private

    def write_to_pipe(pipe, stdin, timeout_checker, close_write: true)
      offset = 0
      length = stdin.bytesize

      while offset < length
        remaining_time = timeout_checker.check!

        if IO.select(nil, [pipe], nil, remaining_time)
          written = pipe.write_nonblock(stdin.byteslice(offset, length), exception: false)
          offset += written if written.is_a?(Integer)
        else
          raise Timeout::Error, "Command timed out"
        end
      end

      pipe.close_write if close_write
    end

    def read_from_pipe(pipe, timeout_checker)
      output = +""

      while (result = pipe.read_nonblock(8192, exception: false))
        remaining_time = timeout_checker.check!
        raise Timeout::Error, "Command timed out" if remaining_time <= 0

        case result
        when :wait_readable
          IO.select([pipe], nil, nil, remaining_time)
        when nil
          break
        else
          output << result
        end
      end

      output
    end

    def wait_or_kill(pid, timeout_checker, err_read, err_write)
      loop do
        remaining_time = timeout_checker.check!
        raise Timeout::Error, "timed out waiting on process" if remaining_time <= 0

        if (_, status = Process.wait2(pid, Process::WNOHANG))

          raise Binaryen::NonZeroExitStatus,
            "command exited with status #{status.exitstatus}" if status.exitstatus != 0

          return true
        else
          sleep(0.1)
        end
      end
    end

    def build_command(*arguments)
      [@cmd] + arguments + @default_args
    end

    def command_path(cmd, ignore_missing)
      Dir[File.join(Binaryen.bindir, cmd)].first || (ignore_missing && cmd)
    end
  end
end
