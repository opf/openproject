class UploadedFile
  attr_reader :pathname

  def initialize(pathname)
    @pathname = pathname
  end

  def path
    pathname.to_s
  end

  def to_s
    path
  end

  def basename
    File.basename(path)
  end

  def self.load_from(path)
    full_path = Rails.root.join(path)
    shared_path = DownloadList::SHARED_PATH.join(File.basename(full_path))
    # with remote drivers, files to upload must be in the shared downloads folder
    FileUtils.cp(full_path, shared_path)
    new(shared_path)
  end
end
