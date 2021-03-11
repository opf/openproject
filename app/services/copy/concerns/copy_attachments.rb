module Copy
  module Concerns
    module CopyAttachments
      ##
      # Tries to copy the given attachment between containers
      def copy_attachments(from_container, to_container_id)
        Attachment.where(container: from_container).find_each do |old_attachment|
          copied = old_attachment.dup
          old_attachment.file.copy_to(copied)

          copied.author = user
          copied.container_type = from_container.class.name
          copied.container_id = to_container_id

          unless copied.save
            Rails.logger.error { "Attachments ##{old_attachment.id} could not be copied: #{copied.errors.full_messages} " }
          end
        rescue StandardError => e
          Rails.logger.error { "Failed to copy attachments from #{from_container} to #{to_container}: #{e}" }
        end
      end
    end
  end
end
