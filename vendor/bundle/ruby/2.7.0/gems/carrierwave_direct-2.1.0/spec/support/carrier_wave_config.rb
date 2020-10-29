# encoding: utf-8

CarrierWave.configure do |config|
  config.fog_provider = 'fog/aws'
  config.fog_credentials = {
    :provider               => 'AWS',
    :aws_access_key_id      => 'AWS_ACCESS_KEY_ID',
    :aws_secret_access_key  => 'AWS_SECRET_ACCESS_KEY'
  }
  config.fog_directory = 'AWS_FOG_DIRECTORY' # bucket name
end

