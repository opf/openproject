require 'carrierwave'

if OpenProject::Configuration.attachments_storage == :fog
  require 'fog/aws/storage'

  CarrierWave.configure do |config|
    config.fog_credentials = OpenProject::Configuration.fog_credentials
    config.fog_directory  = OpenProject::Configuration.fog_directory
    config.fog_public     = false
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
end
