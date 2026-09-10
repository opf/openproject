# frozen_string_literal: true

class DownloadList
  SETTLE_TIME = 0.25

  SHARED_PATH = Pathname.new(
    ENV.fetch("CAPYBARA_DOWNLOADED_FILE_DIR", Rails.root.join("tmp/test/downloads"))
  ).join(
    ENV.fetch("TEST_ENV_NUMBER", "1")
  ).tap(&:mkpath)

  def initialize(pattern: "*")
    @pattern = pattern
    @history = download_paths
    @latest = nil
    @observed_sizes = {}
  end

  def refresh_from(_page)
    Retryable.repeat_until_success(max_seconds: Capybara.default_max_wait_time) do
      path = next_download_path
      break if path.nil? && @latest && File.exist?(@latest)

      raise Capybara::ElementNotFound, "No completed download found" unless path

      unless download_size_stable?(path)
        raise Capybara::ElementNotFound, "Download has not finished writing"
      end

      @latest = path
    end

    @history << @latest unless @history.include?(@latest)
    self
  end

  def latest_download
    return nil if @latest.nil?

    Pathname.new(@latest)
  end

  def latest_downloaded_content
    return nil if @latest.nil?

    Pathname.new(@latest).read
  end

  def self.clear
    Dir[SHARED_PATH.join("*")].each do |file|
      FileUtils.rm_f(file)
    end
  end

  private

  def download_paths
    Dir.glob(SHARED_PATH.join(@pattern).to_s)
  end

  def next_download_path
    (download_paths - @history)
      .reject { |path| path.end_with?(".crdownload") }
      .max_by { |path| File.mtime(path) }
  end

  def download_size_stable?(path)
    size = File.size(path)
    previous_size, unchanged_since = @observed_sizes[path]
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    if size == previous_size
      size.positive? && now - unchanged_since >= SETTLE_TIME
    else
      @observed_sizes[path] = [size, now]
      false
    end
  end
end
