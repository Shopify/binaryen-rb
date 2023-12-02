# frozen_string_literal: true

require "English"
require "shellwords"
require "timeout"

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

    def initialize(cmd, timeout: 10, ignore_missing: false)
      @cmd = command_path(cmd, ignore_missing) || raise(ArgumentError, "command not found: #{cmd}")
      @timeout = timeout
      @default_args = DEFAULT_ARGS_FOR_COMMAND.fetch(cmd, [])
    end

    def run(*arguments, stdin: nil, stderr: File::NULL)
      command = build_command(*arguments)
      pipe = IO.popen(command, "rb+", err: stderr)
      pid = pipe.pid
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      remaining_timeout = @timeout

      if stdin
        start_time, remaining_timeout = write_to_pipe(pipe, stdin, start_time, remaining_timeout)
      end

      output, remaining_timeout = read_from_pipe(pipe, start_time, remaining_timeout)

      wait_or_kill(pid, start_time, remaining_timeout)

      output
    end

    private

    def write_to_pipe(pipe, stdin, start_time, remaining_timeout)
      offset = 0
      length = stdin.bytesize

      while offset < length
        start_time, remaining_timeout = update_timeout(start_time, remaining_timeout)
        if IO.select(nil, [pipe], nil, remaining_timeout)
          written = pipe.write_nonblock(stdin.byteslice(offset, length), exception: false)
          case written
          when Integer
            offset += written
          when :wait_writable
            puts "wait"
            # If the pipe is not ready for writing, retry
          end
        else
          raise Timeout::Error, "Command timed out"
        end
      end

      pipe.close_write
      [start_time, remaining_timeout]
    end

    def read_from_pipe(pipe, start_time, remaining_timeout)
      output = +""

      while (result = pipe.read_nonblock(8192, exception: false))
        start_time, remaining_timeout = update_timeout(start_time, remaining_timeout)

        case result
        when :wait_readable
          IO.select([pipe], nil, nil, remaining_timeout)
        when nil
          break
        else
          output << result
        end
      end

      [output, remaining_timeout]
    end

    def update_timeout(start_time, remaining_timeout)
      elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
      remaining_timeout -= elapsed_time

      raise Timeout::Error, "command timed out" if remaining_timeout <= 0

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      [start_time, remaining_timeout]
    end

    def wait_or_kill(pid, start_time, remaining_timeout)
      while remaining_timeout > 0
        start_time, remaining_timeout = update_timeout(start_time, remaining_timeout)

        if (_, status = Process.wait2(pid, Process::WNOHANG))
          if status.exitstatus != 0
            raise Binaryen::NonZeroExitStatus, "command exited with status #{status.exitstatus}"
          end

          return true
        else
          sleep(0.1)
        end
      end

      Process.kill("KILL", pid)
      raise Timeout::Error, "timed out waiting on process"
    end

    def build_command(*arguments)
      Shellwords.join([@cmd] + arguments + @default_args)
    end

    def command_path(cmd, ignore_missing)
      Dir[File.join(Binaryen.bindir, cmd)].first || (ignore_missing && cmd)
    end
  end
end
