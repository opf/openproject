module IFCModelsHelper
  def attachment_content_url(attachment)
    if attachment.external_storage?
      attachment.external_url
    else
      API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(attachment.id)
    end
  end
end