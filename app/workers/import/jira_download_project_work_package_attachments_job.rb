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

module Import
  class JiraDownloadProjectWorkPackageAttachmentsJob < ProgressableJob
    include Import::JiraJobUtils

    on_complete do
      tagged_log("jira_import_id:#{arguments[0]}",
                 "jira_project_id:#{jira_project_key(arguments[1])}", "jira_object_type:project") do
        Rails.logger.debug "Downloading work package attachments finished"
      end
    end

    def text
      jira_project_name = Import::JiraProject.find(arguments[1]).payload["name"]
      I18n.t(:"admin.jira.run.jobs.#{self.class.to_s.demodulize}.title", jira_project_name:)
    end

    def progress
      jira_import = Import::JiraImport.find(arguments[0])
      cursor = jira_import.get_job_cursor(self)
      if cursor.present?
        jira_attachments = Import::JiraAttachment.where(jira_import:, jira_project_id: arguments[1])
        total = jira_attachments.count
        current = jira_attachments.where(id: ..cursor).count
        percentage = (current.to_f / total * 100).round(2)
        { current:, total:, percentage: }
      else
        { current: 0, total: 0, percentage: 0 }
      end
    end

    def build_enumerator(jira_import_id, jira_project_id, cursor:)
      tagged_log("jira_import_id:#{jira_import_id}",
                 "jira_project_id:#{jira_project_key(jira_project_id)}", "jira_object_type:project") do
        Rails.logger.debug "Downloading work package attachments started"
        prepare_jira_import_ivars(jira_import_id)

        cursor ||= @jira_import.get_job_cursor(self)
        enumerator_builder.active_record_on_records(
          Import::JiraAttachment.where(jira_import_id:, jira_project_id:),
          cursor:
        )
      end
    end

    def each_iteration(jira_attachment, jira_import_id, jira_project_id)
      tagged_log("jira_import_id:#{jira_import_id}",
                 "jira_project_id:#{jira_project_key(jira_project_id)}",
                 "jira_issue_key:#{jira_issue_key(jira_attachment)}",
                 "jira_object_type:attachment",
                 "jira_object_id_or_name:#{jira_attachment.payload['filename']}") do
        Journal::NotificationConfiguration.with(false) do
          Journal::EventConfiguration.with(false) do
            attachment = find_attachment(jira_attachment)

            download_file(jira_attachment.payload, attachment) if attachment&.status_import_prepared?
            @jira_import.set_job_cursor(self, jira_attachment.id)
          end
        end
      end
    end

    private

    def jira_issue_key(jira_attachment)
      Import::JiraIssue.where(id: jira_attachment.jira_issue_id).pick(Arel.sql("payload ->> 'key'"))
    end

    def find_attachment(jira_attachment)
      @jira_import.find_op_leg(jira_attachment)
    rescue Import::JiraOpenProjectReference::LegNotFoundError
      Rails.logger.warn "Attachment no longer exists, skipping its download"
      nil
    end

    def download_file(payload, attachment)
      Rails.logger.debug "Downloading attachment"
      @jira_client.download_attachment(payload["content"], payload["filename"]) do |tempfile|
        store_attachment_file(attachment, tempfile)
      end
    rescue Import::JiraClient::Error => e
      warn_skipped_download(payload, e)
      mark_attachment_as_failed(attachment)
    end

    def store_attachment_file(attachment, tempfile)
      attachment.file = tempfile_named_after(attachment, tempfile)
      attachment.status = :uploaded
      attachment.save!
      # Save changes updated_at, restore it to keep the time the file was attached in Jira.
      attachment.update_column(:updated_at, attachment.created_at)
      attachment.enqueue_jobs
    end

    def mark_attachment_as_failed(attachment)
      attachment.update_columns(status: Attachment.statuses[:import_failed])
    end

    # CarrierWave stores a file under the name it reports, which for a downloaded tempfile is
    # random, so it takes the one prepared from Jira. The tempfile is moved, not copied, into a
    # remote storage's cache.
    def tempfile_named_after(attachment, tempfile)
      Rack::Multipart::UploadedFile
        .new(io: tempfile, filename: attachment.filename, content_type: attachment.content_type)
        .extend(FogFileUploader::MovableSource)
    end

    def warn_skipped_download(payload, error)
      app_backtrace = Rails.backtrace_cleaner.clean(error.backtrace)
      attachment_for_log = payload.slice("id", "size", "self", "content", "filename", "mimeType")

      Rails.logger.warn(
        "Could not download jira import attachment, skipping it. Error: #{error}. " \
        "Attachment: #{attachment_for_log}. Backtrace: #{app_backtrace}."
      )
    end
  end
end
