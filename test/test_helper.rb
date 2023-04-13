# frozen_string_literal: true

if RUBY_PLATFORM.match?(/darwin/)
  $LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
end

require "binaryen"
require "minitest/autorun"
