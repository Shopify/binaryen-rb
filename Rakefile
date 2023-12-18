# frozen_string_literal: true

require_relative "lib/binaryen/version"
require "bundler/setup"
require "rake"
require "rake/testtask"
require "rubocop/rake_task"
require "fileutils"
require "tempfile"
require "open-uri"
require "digest"

BINARYEN_VERSION = Binaryen::BINARYEN_VERSION
GITHUB_REPO = "https://github.com/WebAssembly/binaryen/releases/download/#{BINARYEN_VERSION}"
TMP_DIR = File.join(__dir__, "tmp")
VENDOR_DIR = File.join(__dir__, "vendor")
PKG_DIR = File.join(__dir__, "pkg")
DOWNLOAD_DIR = File.join("tmp", "binaryen-#{BINARYEN_VERSION}")
GEMSPEC_CONTENTS = File.read("binaryen.gemspec")

def download_and_verify_platform_files(platform, file, sha256_file)
  folder = File.join(TMP_DIR, file.split("-")[0..1].join("-"))
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

def unpack_artifacts_for_platform(platform)
  ruby_platform = platform.gsub("macos", "darwin")
  file_name = "binaryen-#{BINARYEN_VERSION}-#{platform}.tar.gz"
  tarball = File.join(DOWNLOAD_DIR, file_name)

  FileUtils.mkdir_p(VENDOR_DIR)
  FileUtils.mkdir_p(PKG_DIR)

  local_vendor_dir = File.join(VENDOR_DIR, ruby_platform)

  return if File.exist?(local_vendor_dir)

  puts "Unpacking artifacts for #{ruby_platform}"
  FileUtils.mkdir_p(local_vendor_dir)
  sh("tar -xzf #{tarball} --strip-components=1 -C #{local_vendor_dir}")
  FileUtils.rm("#{local_vendor_dir}/bin/binaryen-unittests")
end

task :clean do
  rm_rf VENDOR_DIR
  rm_rf TMP_DIR
  rm_rf PKG_DIR
end

desc "Fetches the binaryen artifacts for the arm64-darwin platform"
task "fetch:arm64-darwin" do
  download_and_verify_platform_files(
    "arm64-macos",
    "binaryen-#{BINARYEN_VERSION}-arm64-macos.tar.gz",
    "binaryen-#{BINARYEN_VERSION}-arm64-macos.tar.gz.sha256",
  )

  unpack_artifacts_for_platform("arm64-macos")
end

desc "Fetches the binaryen artifacts for the x86_64-linux platform"
task "fetch:x86_64-linux" do
  download_and_verify_platform_files(
    "x86_64-linux",
    "binaryen-#{BINARYEN_VERSION}-x86_64-linux.tar.gz",
    "binaryen-#{BINARYEN_VERSION}-x86_64-linux.tar.gz.sha256",
  )

  unpack_artifacts_for_platform("x86_64-linux")
end

desc "Fetches the binaryen artifacts for the x86_64-darwin platform"
task "fetch:x86_64-darwin" do
  download_and_verify_platform_files(
    "x86_64-macos",
    "binaryen-#{BINARYEN_VERSION}-x86_64-macos.tar.gz",
    "binaryen-#{BINARYEN_VERSION}-x86_64-macos.tar.gz.sha256",
  )

  unpack_artifacts_for_platform("x86_64-macos")
end

desc "Fetches the binaryen artifacts for all platforms"
multitask fetch: ["fetch:arm64-darwin", "fetch:x86_64-linux", "fetch:x86_64-darwin"]

desc "Builds the binaryen gem"
task build: :fetch do
  outfile = File.join(PKG_DIR, "binaryen-#{Binaryen::VERSION}.gem")

  doit = proc do
    sh("gem build -V binaryen.gemspec --output #{outfile} --strict")
    puts "Built #{outfile}"
  end

  defined?(Bundler) ? Bundler.with_unbundled_env(&doit) : doit.call
end

desc "Installs the binaryen gem"
task install: :build do
  doit = proc do
    sh("gem install #{File.join(PKG_DIR, "binaryen-#{Binaryen::VERSION}.gem")}")
  end

  defined?(Bundler) ? Bundler.with_unbundled_env(&doit) : doit.call
end

Rake::TestTask.new do |t|
  t.libs = FileList["test"]
  t.test_files = FileList["test/**/*_test.rb"]
end

RuboCop::RakeTask.new(:lint)

desc "Runs the examples"
task examples: :install do
  success = true

  Bundler.with_unbundled_env do
    Dir["examples/*.rb"].each do |example|
      puts "👉 Running #{example}"

      if system(RbConfig.ruby, example)
        puts "✅ #{example} ran successfully"
      else
        puts "❌ #{example} failed"
        success &&= false
      end
    end
  end

  exit 1 unless success
end

desc "Releases the binaryen gem"
task release: :build do
  abort "❌ Must be on shipit" unless ENV["SHIPIT"]

  doit = proc do
    sh("gem push #{File.join(PKG_DIR, "binaryen-#{Binaryen::VERSION}.gem")}")
  end

  defined?(Bundler) ? Bundler.with_unbundled_env(&doit) : doit.call
end

task test: :fetch

task default: [:test, :lint]
