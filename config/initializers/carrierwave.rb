require 'carrierwave'

module CarrierWave
  module Configuration
    def self.configure_fog!(credentials: OpenProject::Configuration.fog_credentials,
                            directory: OpenProject::Configuration.fog_directory,
                            public: false)
      require 'fog/aws/storage'

      CarrierWave.configure do |config|
        config.fog_credentials = credentials
        config.fog_directory   = directory
        config.fog_public      = public
      end
    end
  end
end

unless OpenProject::Configuration.fog_credentials.empty?
  CarrierWave::Configuration.configure_fog!
end

CarrierWave::Storage::Fog::File.class_eval do
  ##
  # Fixed filename which was returning invalid values when using S3 as the fog storage
  # due to crappy regex magic.
  def filename(options = {})
    if file_url = url(options)
      uri = URI.parse(file_url)
      path = URI.decode uri.path
      Pathname(path).basename.to_s
    end
  end
end
