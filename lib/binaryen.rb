# frozen_string_literal: true

require "binaryen/version"

module Binaryen
  class << self
    # Path to the vendored binaryen files
    def vendordir
      @vendordir ||= File.expand_path(File.join(File.dirname(__FILE__), "..", "vendor"))
    end

    # Path to the vendored binaryen binary executables
    def bindir
      @bindir ||= File.join(vendordir, "bin")
    end

    # Path to the vendored binaryen libraries
    def libdir
      @libdir ||= File.join(vendordir, "lib")
    end

    # Path to the vendored binaryen headers and definitions
    def includedir
      @includedir ||= File.join(vendordir, "include")
    end
  end
end
