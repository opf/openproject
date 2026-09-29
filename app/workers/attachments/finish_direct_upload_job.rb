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

class Attachments::FinishDirectUploadJob < ApplicationJob
  queue_with_priority :high

  def perform(attachment_id, allowlist: true)
    attachment = Attachment.pending_direct_upload.find_by(id: attachment_id)

    unless attachment
      log_not_found(attachment_id)
      return
    end

    Attachments::FinishDirectUploadService
      .new(user: attachment.author, model: attachment, contract_options: derive_contract_options(allowlist))
      .call
      .on_failure do |call|
      destroy_attachment_and_log_errors(attachment, call.errors) if attachment.reload.prepared?
    end
  end

  private

  def destroy_attachment_and_log_errors(attachment, errors)
    attachment.destroy
    errors = errors.full_messages

    OpenProject.logger.error(
      <<~MSG
        Failed to finish attachment upload for:
          * user: #{attachment.author_id} - #{attachment.author.name}
          * container: #{attachment.container_id} - #{attachment.container}
          * attachment file name: #{attachment.filename}

        Errors:
          #{errors.join("\n          ")}
      MSG
    )
  end

  def log_not_found(attachment_id)
    OpenProject.logger.error("Attachment #{attachment_id} not found")
  end

  def derive_contract_options(allowlist)
    case allowlist
    when false
      { allowlist: [] }
    when Array
      { allowlist: allowlist.map(&:to_s) }
    else
      {}
    end
  end
end
