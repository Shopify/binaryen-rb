# frozen_string_literal: true

module Binaryen
  class Error < StandardError; end
  class NonZeroExitStatus < Error; end
  class MaximumOutputExceeded < Error; end
  class Signal < Error; end
end
