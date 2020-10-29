module CarrierWave

  # this is an internal class, used by CarrierWave::Mount so that
  # we don't pollute the model with a lot of methods.
  class Mounter #:nodoc:
    attr_reader :column, :record, :remote_urls, :integrity_error,
      :processing_error, :download_error
    attr_accessor :remove, :remote_request_headers

    def initialize(record, column, options={})
      @record = record
      @column = column
      @options = record.class.uploader_options[column]
    end

    def uploader_class
      record.class.uploaders[column]
    end

    def blank_uploader
      uploader_class.new(record, column)
    end

    def identifiers
      uploaders.map(&:identifier)
    end

    def read_identifiers
      [record.read_uploader(serialization_column)].flatten.reject(&:blank?)
    end

    def uploaders
      @uploaders ||= read_identifiers.map do |identifier|
        uploader = blank_uploader
        uploader.retrieve_from_store!(identifier) if identifier.present?
        uploader
      end
    end

    def cache(new_files)
      return if not new_files or new_files == ""
      @uploaders = new_files.map do |new_file|
        uploader = blank_uploader
        uploader.cache!(new_file)
        uploader
      end

      @integrity_error = nil
      @processing_error = nil
    rescue CarrierWave::IntegrityError => e
      @integrity_error = e
      raise e unless option(:ignore_integrity_errors)
    rescue CarrierWave::ProcessingError => e
      @processing_error = e
      raise e unless option(:ignore_processing_errors)
    end

    def cache_names
      uploaders.map(&:cache_name).compact
    end

    def cache_names=(cache_names)
      return if not cache_names or cache_names == "" or uploaders.any?(&:cached?)
      @uploaders = cache_names.map do |cache_name|
        uploader = blank_uploader
        uploader.retrieve_from_cache!(cache_name)
        uploader
      end
    rescue CarrierWave::InvalidParameter
    end

    def remote_urls=(urls)
      return if not urls or urls == "" or urls.all?(&:blank?)

      @remote_urls = urls
      @download_error = nil
      @integrity_error = nil

      @uploaders = urls.zip(remote_request_headers || []).map do |url, header|
        uploader = blank_uploader
        uploader.download!(url, header || {})
        uploader
      end

    rescue CarrierWave::DownloadError => e
      @download_error = e
      raise e unless option(:ignore_download_errors)
    rescue CarrierWave::ProcessingError => e
      @processing_error = e
      raise e unless option(:ignore_processing_errors)
    rescue CarrierWave::IntegrityError => e
      @integrity_error = e
      raise e unless option(:ignore_integrity_errors)
    end

    def store!
      if remove?
        remove!
      else
        uploaders.reject(&:blank?).each(&:store!)
      end
    end

    def urls(*args)
      uploaders.map { |u| u.url(*args) }
    end

    def blank?
      uploaders.none?(&:present?)
    end

    def remove?
      remove.present? && remove !~ /\A0|false$\z/
    end

    def remove!
      uploaders.reject(&:blank?).each(&:remove!)
      @uploaders = []
    end

    def serialization_column
      option(:mount_on) || column
    end

    def remove_previous(before=nil, after=nil)
      after ||= []
      return unless before

      # both 'before' and 'after' can be string when 'mount_on' option is set
      before = before.reject(&:blank?).map do |value|
        if value.is_a?(String)
          uploader = blank_uploader
          uploader.retrieve_from_store!(value)
          uploader
        else
          value
        end
      end
      after_paths = after.reject(&:blank?).map do |value|
        if value.is_a?(String)
          uploader = blank_uploader
          uploader.retrieve_from_store!(value)
          uploader
        else
          value
        end.path
      end
      before.each do |uploader|
        if uploader.remove_previously_stored_files_after_update and not after_paths.include?(uploader.path)
          uploader.remove!
        end
      end
    end

    attr_accessor :uploader_options

  private

    def option(name)
      self.uploader_options ||= {}
      self.uploader_options[name] ||= record.class.uploader_option(column, name)
    end

  end # Mounter
end # CarrierWave
