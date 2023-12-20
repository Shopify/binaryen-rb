# frozen_string_literal: true

require_relative "lib/binaryen/version"

Gem::Specification.new do |spec|
  spec.name = "binaryen"
  spec.version = Binaryen::VERSION
  spec.authors = ["Shopify Inc."]
  spec.email = ["gems@shopify.com"]
  spec.summary = "Vendors binaryen libraries, headers, and executables for use in Ruby"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.files = Dir["lib/**/*.rb", "vendor/**/*", "LICENSE", "README.md", "extconf.rb"]
  spec.require_paths = ["lib"]
  spec.licenses = ["Apache-2.0"] # Same as binaryen
  spec.homepage = "https://github.com/Shopify/binaryen-rb"
  spec.platform = Gem::Platform::RUBY
  spec.extensions = ["extconf.rb", "ext/binaryen/extconf.rb"]
  spec.add_dependency("posix-spawn", "~> 0.3.15")
end
