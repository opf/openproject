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

  def perform(attachment_id, whitelist: true)
    attachment = Attachment.pending_direct_upload.find_by(id: attachment_id)
    # An attachment is guaranteed to have a file.
    # But if the attachment is nil the expression attachment&.file will be nil and attachment&.file.local_file
    # will throw a NoMethodError: undefined method local_file' for nil:NilClass`.
    local_file = attachment && attachment.file.local_file

    if local_file.nil?
      return Rails.logger.error("File for attachment #{attachment_id} was not uploaded.")
    end

    User.execute_as(attachment.author) do
      attach_uploaded_file(attachment, local_file, whitelist)
    end
  end

  private

  def attach_uploaded_file(attachment, local_file, whitelist)
    set_attributes_from_file(attachment, local_file)
    validate_attachment(attachment, whitelist)
    save_attachment(attachment)
    journalize_container(attachment)
    attachment_created_event(attachment)
    schedule_jobs(attachment)
  rescue StandardError => e
    ::OpenProject.logger.error e
    attachment.destroy
  ensure
    FileUtils.rm_rf(local_file.path)
  end

  def set_attributes_from_file(attachment, local_file)
    attachment.extend(OpenProject::ChangedBySystem)
    attachment.change_by_system do
      attachment.status = :uploaded
      attachment.set_file_size local_file
      attachment.set_content_type local_file
      attachment.set_digest local_file
    end
  end

  def save_attachment(attachment)
    attachment.save! if attachment.changed?
  end

  def validate_attachment(attachment, whitelist)
    contract = create_contract attachment, whitelist

    unless contract.valid?
      errors = contracterrors.full_messages.join(", ")
      raise "Failed to validate attachment #{attachment.id}: #{errors}"
    end
  end

  def create_contract(attachment, whitelist)
    options = derive_contract_options(whitelist)
    ::Attachments::CreateContract.new attachment,
                                      attachment.author,
                                      options:
  end

  def schedule_jobs(attachment)
    attachment.extract_fulltext
  end

  def derive_contract_options(whitelist)
    case whitelist
    when false
      { whitelist: [] }
    when Array
      { whitelist: whitelist.map(&:to_s) }
    else
      {}
    end
  end

  def journalize_container(attachment)
    journable = attachment.container

    return unless journable&.class&.journaled?

    # Touching the journable will lead to the journal created next having its own timestamp.
    # That timestamp will not adequately reflect the time the attachment was uploaded. This job
    # right here might be executed way later than the time the attachment was uploaded. Ideally,
    # the journals would be created bearing the time stamps of the attachment's created_at.
    # This remains a TODO.
    # But with the timestamp update in place as it is, at least the collapsing of aggregated journals
    # from days before with the newly uploaded attachment is prevented.
    touch_journable(journable)

    Journals::CreateService
      .new(journable, attachment.author)
      .call
  end

  def touch_journable(journable)
    # Not using touch here on purpose,
    # as to avoid changing lock versions on the journables for this change
    attributes = journable.send(:timestamp_attributes_for_update_in_model)

    timestamps = attributes.index_with { Time.now }
    journable.update_columns(timestamps) if timestamps.any?
  end

  def attachment_created_event(attachment)
    OpenProject::Notifications.send(
      OpenProject::Events::ATTACHMENT_CREATED,
      attachment:
    )
  end
end
