# frozen_string_literal: true

require_relative "lib/binaryen/version"
require "rake"
require "rake/testtask"
require "rubocop/rake_task"
require "fileutils"
require "tempfile"
require "open-uri"
require "digest"

BINARYEN_VERSION = Binaryen::BINARYEN_VERSION
GITHUB_REPO = "https://github.com/WebAssembly/binaryen/releases/download/#{BINARYEN_VERSION}"
TMP_DIR = "tmp"
DOWNLOAD_DIR = File.join("tmp", "binaryen-#{BINARYEN_VERSION}")
STAGING_DIR = "tmp/staging"
PKG_DIR = "pkg"

def download_and_verify_platform_files(platform, file, sha256_file)
  folder = File.join(TMP_DIR, file.split("-")[0..1].join("-").gsub("macos", "darwin"))
  FileUtils.mkdir_p(folder)

  sha256_url = "#{GITHUB_REPO}/#{sha256_file}"
  binary_url = "#{GITHUB_REPO}/#{file}"
  binary_path = "#{folder}/#{file}"

  return if File.exist?(binary_path)

  expected_sha256_content = URI.parse(sha256_url).open(redirect: true).read.strip.split(" ").first
  puts "Checksum for #{file} is #{expected_sha256_content.strip}"

  puts "Downloading and verifying #{binary_url} to #{binary_path}"
  URI.parse(binary_url).open(redirect: true) do |src|
    content = src.read
    actual_sha256_digest = Digest::SHA256.hexdigest(content)

    if actual_sha256_digest == expected_sha256_content
      puts "Checksum verified for #{binary_url}. Saving file to #{binary_path}"
      File.binwrite(binary_path, content)
    else
      puts "Checksum verification failed for #{binary_url}. File not saved."
    end
  end
end

def build_gem_for_platform(platform)
  ruby_platform = platform.gsub("macos", "darwin")
  file_name = "binaryen-#{BINARYEN_VERSION}-#{platform}.tar.gz"
  staging_path = File.join(STAGING_DIR, ruby_platform)
  tarball = File.join(DOWNLOAD_DIR, file_name)

  puts "Building gem for #{ruby_platform}"

  FileUtils.rm_rf(staging_path)
  FileUtils.mkdir_p(staging_path)
  FileUtils.rm_f(File.join("pkg", file_name))
  FileUtils.mkdir_p(PKG_DIR)

  sh("tar -xzf #{tarball} -C #{staging_path}")
  FileUtils.mv(File.join(staging_path, "binaryen-#{BINARYEN_VERSION}"), File.join(staging_path, "vendor"))
  FileUtils.cp_r("lib", staging_path)
  FileUtils.cp("binaryen.gemspec", staging_path)

  outpath = File.expand_path(File.join(PKG_DIR, "binaryen-#{Binaryen::VERSION}-#{ruby_platform}.gem"))

  Dir.chdir(staging_path) do
    sh("gem build binaryen.gemspec --platform #{ruby_platform} --output #{outpath}")
  end
end

task "build:arm64-darwin" do
  download_and_verify_platform_files(
    "arm64-macos",
    "binaryen-#{BINARYEN_VERSION}-arm64-macos.tar.gz",
    "binaryen-#{BINARYEN_VERSION}-arm64-macos.tar.gz.sha256",
  )

  build_gem_for_platform("arm64-macos")
end

task "build:x86_64-linux" do
  download_and_verify_platform_files(
    "x86_64-linux",
    "binaryen-#{BINARYEN_VERSION}-x86_64-linux.tar.gz",
    "binaryen-#{BINARYEN_VERSION}-x86_64-linux.tar.gz.sha256",
  )

  build_gem_for_platform("x86_64-linux")
end

task "build:x86_64-darwin" do
  download_and_verify_platform_files(
    "x86_64-macos",
    "binaryen-#{BINARYEN_VERSION}-x86_64-macos.tar.gz",
    "binaryen-#{BINARYEN_VERSION}-x86_64-macos.tar.gz.sha256",
  )

  build_gem_for_platform("x86_64-macos")
end

task build: ["build:arm64-darwin", "build:x86_64-linux", "build:x86_64-darwin"]

task :install do
  local_platform = RUBY_PLATFORM.gsub(/darwin\d+$/, "darwin")
  FileUtils.rm_rf("tmp/gem_home")
  sh "gem install pkg/binaryen-#{Binaryen::VERSION}-#{local_platform}.gem --install-dir tmp/gem_home --no-document"
end

Rake::TestTask.new do |t|
  t.libs = FileList["test", "tmp/gem_home/gems/*/lib"]
  t.test_files = FileList["test/**/*_test.rb"]
end

RuboCop::RakeTask.new

task default: [:build, :install, :test, :rubocop]
