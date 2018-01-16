require 'text_extractor'

class ExtractFulltextJob < ApplicationJob
  # queue_as :text_extraction

  def initialize(attachment_id)
    @attachment_id = attachment_id
  end

  def perform
    if (attachment = find_attachment(@attachment_id) and
        attachment.readable? and
        text = TextExtractor::Resolver.new(attachment.diskfile, attachment.content_type).text)

      attachment.update_column :fulltext, text
    end
  end

  private

  def find_attachment(id)
    Attachment.find_by_id id
  end

end
