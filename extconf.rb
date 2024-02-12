# frozen_string_literal: true

require "mkmf"
require "fileutils"

def log(msg)
  timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
  $stderr.write("[#{timestamp}] [binaryen-rb] " + msg + "\n")
end

def to_mib(bytes)
  (bytes.to_f / 1024.to_f / 1024.to_f).round(2)
end

total_saved = 0

if enable_config("prune", true)
  begin
    log("[info] removing unnecessary vendor directories")

    cpu = RbConfig::CONFIG["host_cpu"]
    os = RbConfig::CONFIG["host_os"]
    if os.include?("darwin")
      os = "darwin"
    end
    ruby_platform = "#{cpu}-#{os}"

    Dir["#{__dir__}/vendor/*"].each do |dir|
      next if dir.end_with?(ruby_platform)

      space_saved = Dir["#{dir}/**/*"].sum { |f| File.file?(f) ? File.size(f) : 0 }
      total_saved += space_saved
      log("[info] removing #{dir} (#{to_mib(space_saved)} MiB saved)")
      FileUtils.rm_rf(dir)
    end
  rescue => e
    log("[warn] failed to remove unnecessary vendor directories: #{e}")
  end
end

File.write("Makefile", <<~MAKEFILE)
  install:
  \t@echo "binaryen-rb does not need to be installed"
MAKEFILE

unless File.exist?("#{__dir__}/vendor/#{ruby_platform}")
  log("[warning] no vendor directory found for #{ruby_platform}, cannot use binaryen-rb on this platform yet")
  exit
end

if enable_config("strip", true)
  begin
    strip_command = RbConfig::MAKEFILE_CONFIG["STRIP"]

    if strip_command.nil?
      log("[warn] no strip command found, skipping")
    else
      Dir["#{__dir__}/vendor/#{ruby_platform}/{lib,bin}/*"].each do |lib|
        start_size = File.size(lib)
        if system("#{strip_command} #{lib}")
          end_size = File.size(lib)
          size_diff = (start_size - end_size)
          total_saved += size_diff
          log("[info] stripped #{lib.sub(__dir__, ".")} (#{size_diff} bytes saved)")
        else
          log("[warn] failed to strip #{lib}")
        end
      end
    end
  rescue => e
    log("[warn] failed to strip binaries: #{e}")
  end
end

log("[info] done (#{to_mib(total_saved)} MiB saved)")
