require 'text_extractor'

class ExtractFulltextJob < ApplicationJob
  # queue_as :text_extraction

  def initialize(attachment_id)
    @attachment_id = attachment_id
  end

  def perform
    attachment = find_attachment(@attachment_id)
    return unless attachment.readable?
    text = TextExtractor::Resolver.new(attachment.diskfile, attachment.content_type).text

    if OpenProject::Database.allows_tsv?
      attachment_filename = attachment.file.file.filename
      update_with_tsv(attachment.id, attachment_filename, text)
    else
      attachment.update(fulltext: text)
    end
  end

  private

  def update_with_tsv(id, filename, text)
    language = OpenProject::Configuration.main_content_language
    update_sql = <<-SQL
          UPDATE "attachments" SET
            fulltext = '%s',
            "fulltext_tsv" = to_tsvector('%s', '%s'),
            "file_tsv" = to_tsvector('%s', '%s')
          WHERE ID = %s;
    SQL

    ActiveRecord::Base.connection.execute ActiveRecord::Base.send(
      :sanitize_sql_array,
      [update_sql,
       text,
       language,
       OpenProject::FullTextSearch.normalize_text(text),
       language,
       OpenProject::FullTextSearch.normalize_text(filename),
       id]
    )
  end

  def find_attachment(id)
    Attachment.find_by_id id
  end

end
