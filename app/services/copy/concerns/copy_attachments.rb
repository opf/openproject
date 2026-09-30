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

module Copy
  module Concerns
    module CopyAttachments
      ##
      # Tries to copy the given attachment between containers
      def copy_attachments(container_type, from:, to:, references: [])
        Attachment
          .where(container_type:, container_id: from.id)
          .find_each do |source|
          copy_attachment(from:, to:, references:, source:)
        end

        if to.changed? && !to.save
          Rails.logger.error { "Failed to update copied attachment references in to #{to}: #{to.errors.full_messages}" }
        end
      end

      def copy_attachment(source:, from:, to:, references:)
        copy = Attachment
          .new(attachment_copy_attributes(source, to.id))
        source.file.copy_to(copy)

        if copy.save
          update_references(
            attachment_source: source.id,
            attachment_target: copy.id,
            model_source: from,
            model_target: to,
            references:
          )
        else
          Rails.logger.error { "Attachments ##{source.id} could not be copy: #{copy.errors.full_messages} " }
        end
      rescue StandardError => e
        Rails.logger.error { "Failed to copy attachments from #{from} to #{to}: #{e}" }
      end

      def attachment_copy_attributes(source, to_id)
        source
          .dup
          .attributes
          .except("file")
          .merge("author_id" => user.id,
                 "container_id" => to_id)
      end

      def update_references(attachment_source:, attachment_target:, model_source:, model_target:, references:)
        references.each do |reference|
          text = model_source.send(reference)
          next if text.nil?

          replaced = text.gsub("/api/v3/attachments/#{attachment_source}/content",
                               "/api/v3/attachments/#{attachment_target}/content")

          model_target.send(:"#{reference}=", replaced)
        end
      end
    end
  end
end
