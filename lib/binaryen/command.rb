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
    MAX_OUTPUT_SIZE = 256 * 1024 * 1024
    DEFAULT_ARGS_FOR_COMMAND = {
      "wasm-opt" => ["--output=-"],
    }.freeze

    def initialize(cmd, timeout: 10, ignore_missing: false)
      @cmd = command_path(cmd, ignore_missing) || raise(ArgumentError, "command not found: #{cmd}")
      @timeout = timeout
      @default_args = DEFAULT_ARGS_FOR_COMMAND.fetch(cmd, [])
    end

    def run(*arguments, stdin: nil, stderr: nil)
      args = [@cmd] + arguments + @default_args
      child = POSIX::Spawn::Child.new(*args, input: stdin, timeout: @timeout, max: MAX_OUTPUT_SIZE)
      stderr&.write(child.err)
      status = child.status

      raise Binaryen::NonZeroExitStatus, "command exited with status #{status.exitstatus}" unless status.success?

      child.out
    rescue POSIX::Spawn::MaximumOutputExceeded => e
      raise Binaryen::MaximumOutputExceeded, e.message
    rescue POSIX::Spawn::TimeoutExceeded => e
      raise Timeout::Error, e.message
    end

    private

    def command_path(cmd, ignore_missing)
      Dir[File.join(Binaryen.bindir, cmd)].first || (ignore_missing && cmd)
    end
  end
end
