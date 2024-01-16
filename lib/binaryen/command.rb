# frozen_string_literal: true

require "posix/spawn"
require "timeout"
require "tempfile"

module Binaryen
  class Command
    include POSIX::Spawn
    DEFAULT_MAX_OUTPUT_SIZE = 256 * 1024 * 1024 * 1024 # 256 MiB
    DEFAULT_TIMEOUT = 10
    DEFAULT_ARGS_FOR_COMMAND = {}.freeze

    def initialize(cmd, timeout: DEFAULT_TIMEOUT, max_output_size: DEFAULT_MAX_OUTPUT_SIZE, ignore_missing: false)
      @cmd = command_path(cmd, ignore_missing) || raise(ArgumentError, "command not found: #{cmd}")
      @timeout = timeout
      @default_args = DEFAULT_ARGS_FOR_COMMAND.fetch(cmd, [])
      @max_output_size = max_output_size
    end

    def run(*arguments, stdin: nil, stderr: nil)
      args = [@cmd] + arguments + @default_args
      Timeout.timeout(@timeout) do
        spawn_command(*args, stderr: stderr, stdin: stdin)
      end
    end

    private

    def command_path(cmd, ignore_missing)
      Dir[File.join(Binaryen.bindir, cmd)].first || (ignore_missing && cmd)
    end

    def spawn_command(*args, stderr: nil, stdin: nil)
      pid = nil

      Tempfile.create("binaryen-input") do |in_write|
        in_write.binmode
        in_write.write(stdin) if stdin
        in_write.close

        Tempfile.create("binaryen-output") do |tmpfile|
          tmpfile.close

          File.open(File::NULL, "w") do |devnull|
            IO.pipe do |err_read, err_write|
              pid = POSIX::Spawn.pspawn(
                *args,
                "--output=#{tmpfile.path}",
                in_write.path,
                in: devnull,
                out: devnull,
                err: err_write,
              )
              err_write.close

              _, status = Process.waitpid2(pid)
              pid = nil

              stderr&.write(err_read.read)
              err_read.close

              if status.signaled?
                raise Binaryen::Signal, "command terminated by signal #{status.termsig}"
              elsif status.exited? && !status.success?
                raise Binaryen::NonZeroExitStatus, "command exited with status #{status.exitstatus}"
              elsif File.size(tmpfile.path) > @max_output_size
                raise Binaryen::MaximumOutputExceeded, "maximum output size exceeded (#{@max_output_size} bytes)"
              end

              File.binread(tmpfile.path)
            end
          end
        rescue
          if pid
            begin
              Process.kill(:KILL, pid)
            rescue SystemCallError
              # Expected
            end

            begin
              Process.wait(pid, Process::WNOHANG)
            rescue SystemCallError
              # Expected
            end
          end

          raise
        end
      end
    end
  end
end
