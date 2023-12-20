# frozen_string_literal: true

if RUBY_PLATFORM.match?(/darwin/)
  $LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
end

require "binaryen"
require "binaryen/ffi"
require "minitest/autorun"

at_exit do
  GC.start(full_mark: true, immediate_sweep: true)
end
