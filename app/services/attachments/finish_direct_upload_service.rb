# frozen_string_literal: true

# -- copyright
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
# ++

module Attachments
  class FinishDirectUploadService < BaseServices::BaseContracted
    def initialize(user:, model:, contract_class: nil, contract_options: {})
      self.model = model
      super(user:, contract_class:, contract_options:)
    end

    protected

    alias_method :attachment, :model

    def service_context(send_notifications:, &)
      # Overwriting the call to in_context to place the semaphore on the container and not on the attachment.
      # Since the service will write a journal on the container, there should not be another
      # process that modifies the container while this service is running.
      in_context(attachment.container, send_notifications:, &)
    end

    def validate_params
      super.tap do |call|
        validate_still_prepared(call)
        validate_staged_file_exists(call) if call.success?
      end
    end

    def before_perform(_)
      super.tap do
        set_attachment_parameters
      end
    end

    def persist(call)
      super.tap do |service_result|
        unless attachment.save
          service_result.errors = attachment.errors
          service_result.success = false
        end
      end
    end

    def after_perform(service_call)
      super.tap do
        journalize_container
        attachment_created_event
        schedule_jobs
        delete_staged_file
      end
    end

    def validate_still_prepared(call)
      attachment.lock!

      unless attachment.prepared?
        call.errors.add(:base, "Upload of attachment #{attachment.filename} has already been completed.")
        call.success = false
      end
    end

    def validate_staged_file_exists(call)
      unless staged_upload.readable?
        call.errors.add(:base, "File for attachment #{attachment.filename} was not uploaded.")
        call.success = false
      end
    end

    def set_attachment_parameters
      attachment.extend(OpenProject::ChangedBySystem)
      attachment.change_by_system do
        attachment.status = :uploaded
        attachment.file = staged_upload.local_file
      end
    end

    def delete_staged_file
      staged_upload.remote_file.delete
    rescue StandardError => e
      OpenProject.logger.error("Failed to delete staged upload of attachment #{attachment.id}: #{e.message}")
    end

    def schedule_jobs
      attachment.enqueue_jobs
    end

    def journalize_container
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

      timestamps = attributes.index_with { Time.current }
      journable.update_columns(timestamps) if timestamps.any?
    end

    def attachment_created_event
      OpenProject::Notifications.send(
        OpenProject::Events::ATTACHMENT_CREATED,
        attachment:
      )
    end

    def default_contract_class
      ::Attachments::CreateContract
    end

    def staged_upload
      @staged_upload ||= DirectFogUploader.for_attachment(attachment)
    end
  end
end
