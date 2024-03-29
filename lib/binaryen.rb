# frozen_string_literal: true

require "binaryen/version"
require "binaryen/error"
require "binaryen/command"

module Binaryen
  class Error < StandardError; end

  class << self
    # Path to the vendored binaryen files
    def vendordir
      @vendordir ||= begin
        cpu = RbConfig::CONFIG["host_cpu"]
        os = RbConfig::CONFIG["host_os"]
        if os.include?("darwin")
          os = "darwin"
        end
        File.expand_path(File.join(File.dirname(__FILE__), "..", "vendor", "#{cpu}-#{os}"))
      end
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
