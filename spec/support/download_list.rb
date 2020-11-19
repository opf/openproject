class DownloadList
  SHARED_PATH = Pathname.new(
    ENV.fetch("CAPYBARA_DOWNLOADED_FILE_DIR", Rails.root.join('tmp/test/downloads'))
  ).join(
    ENV.fetch('TEST_ENV_NUMBER', '1')
  ).tap {|f| p ["DownloadList::SHARED_PATH", f.to_s] ; f.mkpath }

  def initialize
    @history = []
    @latest = nil
  end

  def refresh_from(page)
    @latest = nil
    page.visit("about:downloads")
    # give some time for page to load
    sleep 0.5
    download_name = page.evaluate_script("document.querySelector('downloads-manager').shadowRoot.querySelector('#downloadsList downloads-item').shadowRoot.querySelector('div#content #file-link')").text()
    if download_name && !@history.include?(download_name)
      Timeout.timeout(Capybara.default_max_wait_time) do
        sleep 0.1 until SHARED_PATH.join(download_name).exist?
      end
      @latest = download_name
      @history << @latest
    end
    self
  end

  def latest_download
    return nil if @latest.nil?
    SHARED_PATH.join(@latest)
  end

  def latest_downloaded_content
    return nil if @latest.nil?
    SHARED_PATH.join(@latest).read
  end

  def self.clear
    return if ENV["CI"]
    Dir[SHARED_PATH.join("*")].each do |file|
      FileUtils.rm_f(file)
    end
  end
end
