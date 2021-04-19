module Copy
  module Concerns
    module CopyAttachments
      ##
      # Tries to copy the given attachment between containers
      def copy_attachments(from_container, to_container_id)
        from_container_id = from_container.is_a?(ApplicationRecord) ? from_container.id : from_container
        Attachment.where(container_id: from_container_id).find_each do |old_attachment|
          copied = old_attachment.dup
          old_attachment.file.copy_to(copied)

          copied.author = user
          copied.container_type = old_attachment.container_type
          copied.container_id = to_container_id

          unless copied.save
            Rails.logger.error { "Attachments ##{old_attachment.id} could not be copied: #{copied.errors.full_messages} " }
          end
        rescue StandardError => e
          Rails.logger.error { "Failed to copy attachments from ##{from_container_id} to ##{to_container_id}: #{e}" }
        end
      end
    end
  end
end
