# frozen_string_literal: true

require "posix/spawn"
require "timeout"
require "tempfile"

module Binaryen
  class Command
    include POSIX::Spawn
    DEFAULT_MAX_OUTPUT_SIZE = 256 * 1024 * 1024
    DEFAULT_TIMEOUT = 10
    DEFAULT_ARGS_FOR_COMMAND = {
      "wasm-opt" => ["--output=-"],
    }.freeze

    def initialize(cmd, timeout: DEFAULT_TIMEOUT, max_output_size: DEFAULT_MAX_OUTPUT_SIZE, ignore_missing: false)
      @cmd = command_path(cmd, ignore_missing) || raise(ArgumentError, "command not found: #{cmd}")
      @timeout = timeout
      @default_args = DEFAULT_ARGS_FOR_COMMAND.fetch(cmd, [])
      @max_output_size = max_output_size
    end

    def run(*arguments, stdin: nil, stderr: nil)
      args = [@cmd] + arguments + @default_args

      if stdin
        with_stdin_tempfile(stdin) { |path| spawn_command(*args, path, stderr: stderr) }
      else
        spawn_command(*args, stderr: stderr)
      end
    end

    private

    def with_stdin_tempfile(content)
      Tempfile.open("binaryen-stdin") do |f|
        f.binmode
        f.write(content)
        f.close
        yield f.path
      end
    end

    def command_path(cmd, ignore_missing)
      Dir[File.join(Binaryen.bindir, cmd)].first || (ignore_missing && cmd)
    end

    def spawn_command(*args, stderr: nil)
      out = "".b
      data_buffer = "".b
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      pid, stdin, stdout, stderr_stream = popen4(*args)
      stdin.close
      readers = [stdout, stderr_stream]

      while readers.any?
        elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
        remaining_time = @timeout - elapsed_time
        ready = IO.select(readers, nil, nil, remaining_time)
        raise Timeout::Error, "command timed out after #{@timeout} seconds" if ready.nil?

        ready[0].each do |io|
          max_amount_to_read = @max_output_size - out.bytesize + 1
          data = io.read_nonblock(max_amount_to_read, data_buffer, exception: false)

          if data == :wait_readable
            # If the IO object is not ready for reading, read_nonblock returns :wait_readable.
            # This isn't an error, but a notification.
            next
          elsif data.nil?
            # At EOF, read_nonblock returns nil instead of raising EOFError.
            readers.delete(io)
            io.close
          elsif io == stdout
            out << data_buffer
          elsif io == stderr_stream && stderr
            stderr << data_buffer
          end
        rescue Errno::EINTR
          # This means that the read was interrupted by a signal, which is not an error. So we just retry.
        end

        if out.bytesize > @max_output_size
          Process.kill("TERM", pid)
          raise Binaryen::MaximumOutputExceeded, "maximum output size exceeded (#{@max_output_size} bytes)"
        end

        if remaining_time < 0
          Process.kill("TERM", pid)
          raise Timeout::Error, "command timed out after #{@timeout} seconds"
        end
      end

      _, status = Process.waitpid2(pid, Process::WUNTRACED)

      raise Binaryen::NonZeroExitStatus, "command exited with status #{status.exitstatus}" unless status.success?

      out
    ensure
      [stdin, stdout, stderr_stream].each do |io|
        io.close
      rescue
        nil
      end
    end
  end
end
