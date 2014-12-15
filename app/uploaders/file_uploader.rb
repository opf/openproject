module FileUploader
  def self.included(base)
    base.extend ClassMethods
  end

  def local_file
    file.to_file
  end

  def download_url
    file.is_path? ? file.path : file.url
  end

  def cache_dir
    self.class.cache_dir
  end

  module ClassMethods
    def cache_dir
      @cache_dir ||= begin
        tmp = Tempfile.new 'op_uploaded_files'
        path = Pathname(tmp)

        tmp.delete # delete temp file
        path.mkdir # create temp directory

        path.to_s
      end
    end
  end
end
