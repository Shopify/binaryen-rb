# frozen_string_literal: true

require "test_helper"

class InstallTest < Minitest::Test
  def test_bindir_is_properly_vendored
    result = %x(#{Binaryen.bindir}/wasm-opt --version)
    version = Binaryen::BINARYEN_VERSION.split("_").last

    assert_equal("wasm-opt version #{version} (#{Binaryen::BINARYEN_VERSION})", result.strip)
  end

  def test_libdir_is_properly_vendored
    assert(Dir[Binaryen.libdir + "/*"].any?)
  end

  def test_included_headers_are_properly_vendored
    assert(Dir[Binaryen.includedir + "/*"].any?)
  end
end
