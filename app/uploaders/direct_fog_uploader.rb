require_relative 'fog_file_uploader'

class DirectFogUploader < FogFileUploader
  include CarrierWaveDirect::Uploader

  def self.for_attachment(attachment)
    for_uploader attachment.file
  end

  def self.for_uploader(fog_file_uploader)
    raise ArgumentError, "FogFileUploader expected" unless fog_file_uploader.is_a? FogFileUploader

    uploader = self.new

    uploader.instance_variable_set "@file", fog_file_uploader.file
    uploader.instance_variable_set "@key", fog_file_uploader.path

    uploader
  end

  ##
  # Generates the direct upload form for the given attachment.
  #
  # @param attachment [Attachment] The attachment for which a file is to be uploaded.
  # @param success_action_redirect [String] URL to redirect to if successful (none by default, using status).
  # @param success_action_status [String] The HTTP status to return on success (201 by default).
  # @param max_file_size [Integer] The maximum file size to be allowed in bytes.
  def self.direct_fog_hash(
    attachment:,
    success_action_redirect: nil,
    success_action_status: "201",
    max_file_size: Setting.attachment_max_size * 1024
  )
    uploader = for_attachment attachment

    if success_action_redirect.present?
      uploader.success_action_redirect = success_action_redirect
      uploader.use_action_status = false
    else
      uploader.success_action_status = success_action_status
      uploader.use_action_status = true
    end

    hash = uploader.direct_fog_hash(enforce_utf8: false, max_file_size: max_file_size)

    if success_action_redirect.present?
      hash.merge(success_action_redirect: success_action_redirect)
    else
      hash.merge(success_action_status: success_action_status)
    end
  end
end
