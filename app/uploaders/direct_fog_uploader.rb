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

class DirectFogUploader
  attr_reader :key

  def initialize(attachment)
    @filename = attachment[:file]
    @key = "uploads/direct_uploads/attachment/#{attachment.id}/#{@filename}"
    @storage = AttachmentShrine.storage_for(:s3)
  end

  def self.for_attachment(attachment)
    new(attachment)
  end

  def self.delete_staged_upload(attachment)
    for_attachment(attachment).delete
  rescue StandardError => e
    OpenProject.logger.error("Failed to delete staged upload of attachment #{attachment.id}: #{e.message}")
  end

  def self.direct_fog_hash(attachment:, success_action_redirect: nil, success_action_status: "201",
                           max_file_size: Setting.attachment_max_size * 1024)
    success = if success_action_redirect.present?
                { success_action_redirect: }
              else
                { success_action_status: }
              end
    for_attachment(attachment).form(content_type: attachment.content_type, max_file_size:, **success)
  end

  def form(content_type:, max_file_size:, **success)
    expiration = OpenProject::Configuration.fog_direct_upload_expires_in.seconds.from_now
    form = @storage.presign(key, method: :post, signature_expiration: expiration, content_length_range: 0..max_file_size,
                                 content_type:, **success)
    fields = form.fetch(:fields).symbolize_keys
    fields[:bucket] = @storage.bucket.name if @storage.client.config.force_path_style
    fields.merge(uri: form.fetch(:url))
  end

  def download_url(options = {})
    expiry = OpenProject::Configuration.fog_download_url_expires_in
    @storage.url(key, response_content_type: options[:content_type],
                      response_content_disposition: options[:content_disposition],
                      expires_in: [options[:expires_in], expiry].compact.min.to_i)
  end

  def readable?
    @storage.exists?(key)
  rescue Aws::S3::Errors::Forbidden
    false
  end

  def with_local_file
    Tempfile.create(["staged-upload", File.extname(@filename)], binmode: true) do |file|
      input = @storage.open(key, rewindable: false)
      begin
        IO.copy_stream(input, file)
      ensure
        input.close
      end
      file.rewind
      yield file
    end
  end

  def delete
    @storage.delete(key)
  end
end
