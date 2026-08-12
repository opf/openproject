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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Attachments
  class CreateContract < ::ModelContract
    attribute :file
    attribute :filename
    attribute :filesize
    attribute :digest
    attribute :description
    attribute :content_type
    attribute :charset
    attribute :container
    attribute :container_type
    attribute :author

    validates :filename, presence: true

    validate :validate_attachments_addable
    validate :validate_container_addable
    validate :validate_author
    validate :validate_content_type

    private

    def validate_attachments_addable
      return if model.container

      if Redmine::Acts::Attachable.attachables.none?(&:uncontainered_attachable?)
        errors.add(:base, :error_unauthorized)
      end
    end

    def validate_author
      unless model.author == user
        errors.add(:author, :invalid)
      end
    end

    def validate_container_addable
      return unless model.container

      errors.add(:base, :error_unauthorized) unless model.container.attachments_addable?(user)
    end

    ##
    # Validates the content type, if a allowlist is set
    def validate_content_type
      # If the allowlist is empty, assume all files are allowed
      # as before
      unless matches_allowlist?(attachment_allowlist)
        Rails.logger.info { "Uploaded file #{model.filename} with type #{model.content_type} does not match allowlist" }
        errors.add :content_type, :not_allowlisted, value: model.content_type
      end
    end

    ##
    # Get the user-defined allowlist or a custom allowlist
    # defined for this invocation
    def attachment_allowlist
      Array(options.fetch(:allowlist, Setting.attachment_whitelist))
    end

    ##
    # Returns whether the attachment matches the allowlist
    def matches_allowlist?(allowlist)
      return true if allowlist.empty?

      allowlist.include?(model.content_type) || allowlist.include?("*#{model.extension}")
    end
  end
end
