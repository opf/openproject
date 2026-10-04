# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
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
      @filename = carrierwave_uploader.file.filename

      if @attachment.readable?
        @file = carrierwave_uploader.local_file
        resolver = Plaintext::Resolver.new(@file, @attachment.content_type)
        @text = resolver.text
      end
    rescue StandardError => e
      log_error("Failed to extract plaintext for attachment ##{@attachment&.id}", e)
      update # Still update tsv values
      raise
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
      log_error("Failed to update TSV values for attachment ##{@attachment&.id}", e)
      raise
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

    def log_error(message, cause)
      message += " (on domain #{Setting.host_name})"
      Rails.logger.error("#{message}: #{cause.message.truncate(500, omission: '[...]')}")
    end
  end
end
