# frozen_string_literal: true

require "test_helper"

class InstallTest < Minitest::Test
  def test_bindir_is_properly_vendored
    result = %x(#{Binaryen.bindir}/wasm-opt --version)
    version = Binaryen::VERSION.gsub(".", "")

    assert_equal("wasm-opt version #{version} (version_#{version})", result.strip)
  end

  def test_libdir_is_properly_vendored
    assert(Dir[Binaryen.libdir + "/*"].any?)
  end

  def test_included_headers_are_properly_vendored
    assert(Dir[Binaryen.includedir + "/*"].any?)
  end
end
