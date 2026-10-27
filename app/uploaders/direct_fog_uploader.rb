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

require_relative "fog_file_uploader"

class DirectFogUploader < FogFileUploader
  include CarrierWaveDirect::Uploader

  ##
  # This needs to be true so that the necessary condition is included
  # in S3 upload policy (only relevant for direct uploads).
  def will_include_content_type # rubocop:disable Naming/PredicateMethod
    true
  end

  def upload_expiration
    OpenProject::Configuration.fog_direct_upload_expires_in
  end

  # The signed policy restricts the key via `starts-with`, so this must never be a prefix
  # of the final store_dir the attachment is served from.
  def store_dir
    "uploads/direct_uploads/attachment/#{model.id}"
  end

  class << self
    def for_attachment(attachment)
      new(attachment).tap do |uploader|
        uploader.retrieve_from_store!(attachment[:file])
        uploader.key = uploader.file.path
      end
    end

    def delete_staged_upload(attachment)
      for_attachment(attachment).remote_file.delete
    rescue StandardError => e
      OpenProject.logger.error("Failed to delete staged upload of attachment #{attachment.id}: #{e.message}")
    end

    ##
    # Generates the direct upload form for the given attachment.
    #
    # @param attachment [Attachment] The attachment for which a file is to be uploaded.
    # @param success_action_redirect [String] URL to redirect to if successful (none by default, using status).
    # @param success_action_status [String] The HTTP status to return on success (201 by default).
    # @param max_file_size [Integer] The maximum file size to be allowed in bytes.
    def direct_fog_hash(
      attachment:,
      success_action_redirect: nil,
      success_action_status: "201",
      max_file_size: Setting.attachment_max_size * 1024
    )
      uploader = direct_fog_hash_uploader attachment, success_action_redirect, success_action_status
      hash = uploader
        .direct_fog_hash(enforce_utf8: false, max_file_size:)
        .merge(extra_fog_hash_attributes(uploader:))

      if success_action_redirect.present?
        hash.merge(success_action_redirect:)
      else
        hash.merge(success_action_status:)
      end
    end

    def extra_fog_hash_attributes(uploader:)
      return {} unless include_content_type?(uploader)

      {
        "Content-Type": uploader.fog_attributes[:"Content-Type"]
      }
    end

    private

    def include_content_type?(uploader)
      uploader.will_include_content_type && uploader.fog_attributes.include?(:"Content-Type")
    end

    def direct_fog_hash_uploader(attachment, success_action_redirect, success_action_status)
      for_attachment(attachment).tap do |uploader|
        if success_action_redirect.present?
          uploader.success_action_redirect = success_action_redirect
          uploader.use_action_status = false
        else
          uploader.success_action_status = success_action_status
          uploader.use_action_status = true
        end
      end
    end
  end
end
