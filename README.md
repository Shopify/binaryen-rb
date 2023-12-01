# `binaryen-rb`

[![Gem Version](https://badge.fury.io/rb/binaryen.svg)](https://badge.fury.io/rb/binaryen) | [![CI](https://github.com/Shopify/binaryen-rb/actions/workflows/test.yml/badge.svg)](https://github.com/Shopify/binaryen-rb/actions/workflows/test.yml)

A small gem which vendors [`binaryen` releases][binaryen] for easy use from Ruby. It includes the following executables:

Here's a version of the table with the descriptions shortened to a single sentence:

| exe                        | description                                                                                                              |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `wasm-split`               | Splits a module into a primary and a secondary module, or instruments a module to gather a profile for future splitting. |
| `wasm-ctor-eval`           | Executes code at compile time.                                                                                           |
| `wasm-merge`               | Merges multiple wasm files into one.                                                                                     |
| `wasm-reduce`              | Reduces a wasm file to a smaller one with the same behavior on a given command.                                          |
| `wasm-metadce`             | Performs dead code elimination (DCE) on a larger space that the wasm module is just a part of.                           |
| `wasm-shell`               | Executes .wast files.                                                                                                    |
| `wasm-fuzz-types`          | Fuzzes type construction, canonicalization, and operations.                                                              |
| `wasm-fuzz-lattices`       | Fuzzes lattices for reflexivity, transitivity, and anti-symmetry, and transfer functions for monotonicity.               |
| `wasm-emscripten-finalize` | Performs Emscripten-specific transforms on .wasm files.                                                                  |
| `wasm-as`                  | Assembles a .wat (WebAssembly text format) into a .wasm (WebAssembly binary format).                                     |
| `wasm-opt`                 | Reads, writes, and optimizes files.                                                                                      |
| `wasm-dis`                 | Un-assembles a .wasm (WebAssembly binary format) into a .wat (WebAssembly text format).                                  |
| `wasm2js`                  | Transforms .wasm/.wat files to asm.js.                                                                                   |

Please note that these are simplified descriptions and may not fully capture the functionality of each command. For a complete understanding, refer to the original descriptions or the respective command's documentation.
It also include `libinaryen` and it's corresponding header files, if you need them.

## Installation

Add the following to your Gemfile:

```ruby
gem "binaryen"
```

Then run `bundle install`.

## Usage

This library only contains vendored executables, and minimal Ruby code to invoke
them. You can see some examples of how to use this gem in the
[`./examples`](./examples) directory.

- [`./examples/wasm_opt.rb`](./examples/wasm_opt.rb) - Optimize a WebAssembly module
- [`./examples/wasm_strip.rb`](./examples/wasm_strip.rb) - Strip a WebAssembly module

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/Shopify/binaryen-rb. Signing Shopify's CLA is a mandatory
when opening, you will be prompted to do so by a Github action.

Read and follow the guidelines in [CONTRIBUTING.md](./CONTRIBUTING.md).

## Releases

This gem is published to [Rubygems][rubygems].

The procedure to publish a new release version is as follows:

* Update `lib/binaryen/version.rb` to a valid [`binaryen` release version][binaryen]
* Run bundle install to bump the version of the gem in `Gemfile.lock`
* Open a pull request, review, and merge
* Review commits since the last release to identify user-facing changes that should be included in the release notes
* [Create a relase on GitHub][gh-release] with a version number that matches `lib/binaryen/version.rb`. Pick the `Create new tag` option. More on [creating releases][gh-release-notes]
* [Deploy via Shipit][shipit] and see your [latest version on Rubygems][rubygems]


[binaryen]: https://github.com/WebAssembly/binaryen/releases
[rubygems]: https://rubygems.org/gems/binaryen
[shipit]: https://shipit.shopify.io/shopify/binaryen-rb/release
[gh-release]: https://github.com/Shopify/binaryen-rb/releases/new
[gh-release-notes]: https://help.github.com/articles/creating-releases
