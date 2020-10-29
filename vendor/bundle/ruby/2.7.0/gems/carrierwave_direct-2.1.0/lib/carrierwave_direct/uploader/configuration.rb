# encoding: utf-8

module CarrierWaveDirect
  module Uploader
    module Configuration
      extend ActiveSupport::Concern

      included do
        add_config :validate_is_attached
        add_config :validate_is_uploaded
        add_config :validate_unique_filename
        add_config :validate_filename_format
        add_config :validate_remote_net_url_format

        add_config :min_file_size
        add_config :max_file_size
        add_config :upload_expiration

        add_config :will_include_content_type #alias for default_content_type
        add_config :default_content_type
        add_config :allowed_content_types

        add_config :use_action_status

        reset_direct_config
      end

      module ClassMethods
        def reset_direct_config
          configure do |config|
            config.validate_is_attached = false
            config.validate_is_uploaded = false
            config.validate_unique_filename = true
            config.validate_filename_format = true
            config.validate_remote_net_url_format = true

            config.min_file_size = 1
            config.max_file_size = 5242880
            config.upload_expiration = 36000

            config.use_action_status = false
          end
        end
      end
    end
  end
end

