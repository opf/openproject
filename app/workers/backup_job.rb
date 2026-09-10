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

require "tempfile"
require "zip"

class BackupJob < ApplicationJob
  include OpenProject::PostgresEnvironment

  queue_with_priority :above_normal

  attr_reader :backup, :user

  def perform(
    backup:,
    user:,
    include_attachments: Backup.include_attachments?,
    attachment_size_max_sum_mb: Backup.attachment_size_max_sum_mb
  )
    @backup = backup
    @user = user
    @include_attachments = include_attachments
    @attachment_size_max_sum_mb = attachment_size_max_sum_mb

    run_backup!
  rescue StandardError => e
    failure! error: e.message

    raise e
  ensure
    after_backup
  end

  def run_backup!
    @dumped = dump_database! db_dump_file_name # sets error on failure

    return unless dumped?

    file_name = create_backup_archive!(
      file_name: archive_file_name,
      db_dump_file_name:
    )

    store_backup(file_name, backup:, user:)
    cleanup_previous_backups!

    notify_backup_ready!
  end

  def after_backup
    # Always try to remove the archive path. After a successful fog upload the
    # file has already been moved into CarrierWave's cache (no-op here). After a
    # local copy, or if storing the backup failed, this prevents a leftover large tmpfile
    remove_files! db_dump_file_name, archive_file_name
    remove_backup_attachment! unless success?

    Rails.logger.info(
      "BackupJob(include_attachments: #{include_attachments?}) finished " \
      "with status #{status} " \
      "(dumped: #{dumped?}, archived: #{archived?})"
    )
  end

  def notify_backup_ready!
    UserMailer.backup_ready(user, missing_attachments_count: missing_attachments.size).deliver_later
  end

  def dumped?
    @dumped
  end

  def archived?
    @archived
  end

  delegate :status, to: :job_status

  def db_dump_file_name
    @db_dump_file_name ||= tmp_file_name "openproject", ".sql"
  end

  def archive_file_name
    @archive_file_name ||= tmp_file_name "openproject-backup", ".zip"
  end

  def status_reference
    arguments.first[:backup]
  end

  def updates_own_status?
    true
  end

  def cleanup_previous_backups!
    Backup.where.not(id: backup.id).destroy_all
  end

  def success?
    job_status.status == JobStatus::Status.statuses[:success]
  end

  def remove_files!(*files)
    Array(files).each do |file|
      FileUtils.rm_rf file
    end
  end

  def remove_backup_attachment!
    backup.attachments.each(&:destroy)
  end

  def store_backup(file_name, backup:, user:)
    File.open(file_name) do |file|
      file.extend FogFileUploader::MovableSource

      call = Attachments::CreateService
        .bypass_allowlist(user:)
        .call(container: backup, filename: file_name, file:, description: "OpenProject backup")

      call.on_success { upsert_success_status! call.result }

      call.on_failure do
        upsert_status status: :failure,
                      message: I18n.t("export.failed", message: call.message)
      end
    end
  end

  def upsert_success_status!(result)
    download_url = ::API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(result.id)

    upsert_status(
      status: :success,
      message: I18n.t("export.succeeded"),
      payload: success_status_payload(download_url)
    )
  end

  def success_status_payload(download_url)
    payload = download_payload(download_url, "application/zip")
    payload = payload.merge(html: missing_attachments_html) if missing_attachments.any?

    payload
  end

  def create_backup_archive!(file_name:, db_dump_file_name:, attachments: attachments_to_include)
    Zip::OutputStream.open(file_name) do |zos|
      attachments.each do |attachment|
        archive_attachment! zos, attachment
      end

      write_missing_attachments! zos
      write_to_archive! zos, "openproject.sql", db_dump_file_name
    end

    @archived = true

    finalize_archive_file_name! file_name
  end

  def finalize_archive_file_name!(file_name)
    return file_name if missing_attachments.empty?

    incomplete_file_name = file_name.sub(/\.zip\z/, "-incomplete.zip")
    File.rename(file_name, incomplete_file_name)

    @archive_file_name = incomplete_file_name
  end

  ##
  # Adds a local file to the given ZIP archive.
  #
  # @param zos [Zip::OutputStream] Stream to ZIP archive
  # @param entry_name [String] Name of the zip entry / file
  # @param path [String] Path to local file to be written to stream
  def write_to_archive!(zos, entry_name, path)
    zos.put_next_entry entry_name

    File.open(path, "rb") do |file|
      ::Zip::IOExtras.copy_stream zos, file # copies file to zos
    end
  end

  ##
  # Adds an attachment to the archive. The content is fully received into a
  # tempfile first so a failed download cannot leave a truncated zip entry
  # (Zip::OutputStream cannot unwrite an already-opened member).
  #
  # Peak extra disk is one attachment at a time; the tempfile is unlinked when
  # this method returns.
  #
  # @param zos [Zip::OutputStream] Stream to archive
  # @param attachment [Attachment] Attachment
  def archive_attachment!(zos, attachment)
    # If an attachment is destroyed/missing, skip it
    return missing_attachments << attachment unless attachment.file.readable?

    archive_readable_attachment!(zos, attachment)
  rescue StandardError => e
    log_attachment_error!(attachment, e)

    missing_attachments << attachment
  end

  def archive_readable_attachment!(zos, attachment)
    Tempfile.create(["backup-attachment-#{attachment.id}", ".bin"]) do |tmp|
      tmp.binmode
      attachment.file.stream_to(tmp)
      tmp.flush

      write_to_archive! zos, backup_attachment_entry_name(attachment), tmp.path
    end
  end

  def backup_attachment_entry_name(attachment)
    "attachment/file/#{attachment.id}/#{attachment[:file]}"
  end

  def log_attachment_error!(attachment, error)
    Rails.logger.error do
      "Failed to access attachment #{attachment.id} #{attachment.file&.path} for backup: #{error.message}"
    end
  end

  def missing_attachments
    @missing_attachments ||= []
  end

  def write_missing_attachments!(zos)
    return if missing_attachments.empty?

    zos.put_next_entry "MISSING_ATTACHMENTS.txt"
    zos.write missing_attachments_content
  end

  def missing_attachments_html
    I18n.t(
      "backup.missing_attachments_notice_html",
      file_count: I18n.t(:label_x_files, count: missing_attachments.size)
    )
  end

  def missing_attachments_content
    lines = missing_attachments.map { |attachment| "#{attachment.id}\t#{attachment[:file]}" }

    <<~TEXT
      The following attachments could not be read and were not included in this backup:

      #{lines.join("\n")}
    TEXT
  end

  def attachments_to_include
    return Attachment.none if skip_attachments?

    Backup.attachments_query
  end

  def skip_attachments?
    !(include_attachments? && Backup.attachments_size_in_bounds?(max: attachment_size_max_sum_mb))
  end

  def date_tag
    Time.zone.today.iso8601
  end

  def tmp_file_name(name, ext)
    file = Tempfile.new [name, ext]

    file.path
  ensure
    file.close
    file.unlink
  end

  def include_attachments?
    @include_attachments
  end

  def attachment_size_max_sum_mb
    @attachment_size_max_sum_mb
  end

  def dump_database!(path)
    _out, err, st = Open3.capture3 pg_env, dump_command(path)

    failure! error: err unless st.success?

    st.success?
  end

  def dump_command(output_file_path)
    "pg_dump -x -O -f '#{output_file_path}'"
  end

  def failure!(error: nil)
    msg = I18n.t "backup.failed"

    upsert_status(
      status: :failure,
      message: error.present? ? "#{msg}: #{error}" : msg
    )
  end
end
