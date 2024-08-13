#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Attachments
  class ExtractFulltextJob < ApplicationJob
    queue_with_priority :low

    def perform(attachment_id)
      @attachment_id = attachment_id
      @attachment = nil
      @text = nil
      @file = nil
      @filename = nil
      @language = OpenProject::Configuration.main_content_language

      return unless OpenProject::Database.allows_tsv?
      return unless @attachment = find_attachment(attachment_id)

      init
      update
    ensure
      FileUtils.rm @file.path if delete_file?
    end

    private

    def init
      carrierwave_uploader = @attachment.file
      @file = carrierwave_uploader.local_file
      @filename = carrierwave_uploader.file.filename

      if @attachment.readable?
        resolver = Plaintext::Resolver.new(@file, @attachment.content_type)
        @text = resolver.text
      end
    rescue StandardError => e
      Rails.logger.error(
        "Failed to extract plaintext from file #{@attachment&.id} (On domain #{Setting.host_name}): #{e}: #{e.message}"
      )
    end

    def update
      Attachment
        .where(id: @attachment_id)
        .update_all(["fulltext = ?, fulltext_tsv = to_tsvector(?, ?), file_tsv = to_tsvector(?, ?)",
                     @text,
                     @language,
                     OpenProject::FullTextSearch.normalize_text(@text),
                     @language,
                     OpenProject::FullTextSearch.normalize_filename(@filename)])
    rescue StandardError => e
      Rails.logger.error(
        "Failed to update TSV values for attachment #{@attachment&.id} (On domain #{Setting.host_name}): #{e.message[0..499]}[...]"
      )
    end

    def find_attachment(id)
      Attachment.find_by(id:)
    end

    def remote_file?
      !@attachment&.file.is_a?(LocalFileUploader)
    end

    def delete_file?
      remote_file? && @file
    end
  end
end
