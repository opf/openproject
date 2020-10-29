# encoding: utf-8

require "securerandom"
require "carrierwave_direct/uploader/content_type"
require "carrierwave_direct/policies/aws_base64_sha1"
require "carrierwave_direct/policies/aws4_hmac_sha256"

module CarrierWaveDirect
  module Uploader
    extend ActiveSupport::Concern

    FILENAME_WILDCARD = "${filename}"

    included do
      storage :fog

      attr_accessor :success_action_redirect
      attr_accessor :success_action_status

      fog_credentials.keys.each do |key|
        define_method(key) do
          fog_credentials[key]
        end
      end
    end

    include CarrierWaveDirect::Uploader::ContentType

    #ensure that region returns something. Since sig v4 it is required in the signing key & credentials
    def region
      defined?(super) ? super : "us-east-1"
    end

    def acl
      fog_public ? 'public-read' : 'private'
    end

    def policy(options = {}, &block)
      signing_policy.policy(options, &block)
    end

    def date
      signing_policy.date
    end

    def algorithm
      signing_policy.algorithm
    end

    def credential
      signing_policy.credential
    end

    def clear_policy!
      signing_policy.clear!
    end

    def signature
      signing_policy.signature
    end

    def url_scheme_white_list
      nil
    end

    def persisted?
      false
    end

    def signing_policy_class
      @signing_policy_class ||= Policies::Aws4HmacSha256
    end

    def signing_policy_class=(signing_policy_class)
      @signing_policy_class = signing_policy_class
    end

    def key
      return @key if @key.present?
      if present?
        identifier = model.send("#{mounted_as}_identifier")
        self.key = [store_dir, identifier].join("/")
      else
        guid = SecureRandom.uuid
        @key = [store_dir, guid, FILENAME_WILDCARD].join("/")
      end
      @key
    end

    def key=(k)
      @key = k
      update_version_keys(:with => @key)
    end

    def has_key?
      key !~ /#{Regexp.escape(FILENAME_WILDCARD)}\z/
    end

    def key_regexp
      /\A(#{store_dir}|#{cache_dir})\/[a-f\d\-]+\/.+\.(?i)#{extension_regexp}(?-i)\z/
    end

    def extension_regexp
      allowed_file_types = extension_whitelist
      extension_regexp = allowed_file_types.present? && allowed_file_types.any? ?  "(#{allowed_file_types.join("|")})" : "\\w+"
    end

    def filename
      unless has_key?
        # Use the attached models remote url to generate a new key otherwise return nil
        remote_url = model.send("remote_#{mounted_as}_url")
        if remote_url
          key_from_file(CarrierWave::SanitizedFile.new(remote_url).filename)
        else
          return
        end
      end

      key_parts = key.split("/")
      filename  = key_parts.pop
      guid      = key_parts.pop

      filename_parts = []
      filename_parts << guid if guid
      filename_parts << filename
      filename_parts.join("/")
    end

    def direct_fog_url
      CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), nil).public_url
    end

    def direct_fog_hash(policy_options = {})
      signing_policy.direct_fog_hash(policy_options)
    end

    private

    def key_from_file(filename)
      new_key_parts = key.split("/")
      new_key_parts.pop
      new_key_parts << filename
      self.key = new_key_parts.join("/")
    end

    # Update the versions to use this key
    def update_version_keys(options)
      versions.each do |name, uploader|
        uploader.key = options[:with]
      end
    end

    # Put the version name at the end of the filename since the guid is also stored
    # e.g. guid/filename_thumb.jpg instead of CarrierWave's default: thumb_guid/filename.jpg
    def full_filename(for_file)
      extname = File.extname(for_file)
      [for_file.chomp(extname), version_name].compact.join('_') << extname
    end

    def signing_policy
      @signing_policy ||= signing_policy_class.new(self)
    end
  end
end
