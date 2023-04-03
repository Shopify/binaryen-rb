# `binaryen-rb`

[![Latest version of 'binaryen' @ Cloudsmith](https://api-prd.cloudsmith.io/v1/badges/version/shopify/gems/ruby/binaryen/latest/a=arm64-darwin;xp=arm64-darwin/?render=true&show_latest=true&badge_token=gAAAAABkK04DV1HW1IJsownx5q-cChJ6cFdRDg24g8RHpDMUkX3k_bPW1hcwcldoJ-m2uO3wwFPO7E9Z1D8xu1l-PHghoV7q8Pj0jYHuZ5ce3iHVMVgdMvE%3D)](https://cloudsmith.io/~shopify/repos/gems/packages/detail/ruby/binaryen/latest/a=arm64-darwin;xp=arm64-darwin/)
[![Build status](https://badge.buildkite.com/add062a055afaa789b95b55688346674dfcaaea0c962470740.svg)](https://buildkite.com/shopify/binaryen-rb)

A small gem which vendors [`binaryen` releases][binaryen] for common Ruby platforms.

|       |                                                                      |
| ----- | -------------------------------------------------------------------- |
| Owner | [@Shopify/liquid-perf](https://github.com/orgs/Shopify/teams/liquid-perf)    |
| Help  | [#liquid-perf](https://shopify.slack.com/archives/C03AE40AL1W) |

## How to install this library

Add the following to your Gemfile:

```ruby
gem "binaryen", source: "https://pkgs.shopify.io/basic/gems/ruby"
```

Then run `bundle install`.

## How to use this library

This library only contains vendored binaries, and minimal Ruby code. It is
intended to be used by other gems which depend on `binaryen`.

```ruby
require "binaryen"

system(Binaryen.bindir + "/wasm-opt", "--version") #=> wasm-opt version 112 (version_112)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/Shopify/binaryen-rb. Signing Shopify's CLA is a mandatory
when opening, you will be prompted to do so by a Github action.

Read and follow the guidelines in [CONTRIBUTING.md](https://github.com/Shopify/binaryen-rb/blob/main/CONTRIBUTING.md).

## Releases

This gem is published to [Cloudsmith](https://cloudsmith.io/~shopify/repos/gems/packages).

The procedure to publish a new release version is as follows:

* Update `lib/binaryen/version.rb` to a valid [`binaryen` release version][binaryen]
* Run bundle install to bump the version of the gem in `Gemfile.lock`
* Open a pull request, review, and merge
* Review commits since the last release to identify user-facing changes that should be included in the release notes
* [Create a release on GitHub](https://github.com/Shopify/binaryen-rb/releases/new) with a version number that matches `lib/binaryen/version.rb`. More on [creating releases](https://help.github.com/articles/creating-releases).
* [Deploy via Shipit](https://shipit.shopify.io/shopify/binaryen-rb/cloudsmith) and see your [latest version on Cloudsmith](https://cloudsmith.io/~shopify/repos/gems/packages/detail/ruby/binaryen-rb/latest)


[binaryen]: https://github.com/WebAssembly/binaryen/releases
