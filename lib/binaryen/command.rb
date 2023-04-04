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
  #   optimized_wasm = command.run("-O4", stdin: "(module)").read
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
      pid = nil
      command = build_command(*arguments)
      Timeout.timeout(@timeout) do
        pipe = IO.popen(command, "rb+", err: stderr)
        pid = pipe.pid
        pipe.write(stdin) if stdin
        pipe.close_write
        output = pipe
        Process.wait(pid)
        pid = nil

        if $CHILD_STATUS.exitstatus != 0
          raise Binaryen::NonZeroExitStatus, "command exited with status #{$CHILD_STATUS.exitstatus}: #{command}"
        end

        output
      end
    end

    private

    def build_command(*arguments)
      Shellwords.join([@cmd] + arguments + @default_args)
    end

    def command_path(cmd, ignore_missing)
      Dir[File.join(Binaryen.bindir, cmd)].first || (ignore_missing && cmd)
    end
  end
end
