module Copy
  module Concerns
    module CopyAttachments
      ##
      # Tries to copy the given attachment between containers
      def copy_attachments(container_type, from_id:, to_id:)
        Attachment
          .where(container_type:, container_id: from_id)
          .find_each do |source|
          copy = Attachment
                   .new(attachment_copy_attributes(source, to_id))
          source.file.copy_to(copy)

          unless copy.save
            Rails.logger.error { "Attachments ##{source.id} could not be copy: #{copy.errors.full_messages} " }
          end
        rescue StandardError => e
          Rails.logger.error { "Failed to copy attachments from ##{from_id} to ##{to_id}: #{e}" }
        end
      end

      def attachment_copy_attributes(source, to_id)
        source
          .dup
          .attributes
          .except('file')
          .merge('author_id' => user.id,
                 'container_id' => to_id)
      end
    end
  end
end
