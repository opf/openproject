#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require 'tempfile'
require 'zip'

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
    remove_files! db_dump_file_name, archive_file_name
    remove_backup_attachment! unless success?

    Rails.logger.info(
      "BackupJob(include_attachments: #{include_attachments?}) finished " \
      "with status #{status} " \
      "(dumped: #{dumped?}, archived: #{archived?})"
    )
  end

  def notify_backup_ready!
    UserMailer.backup_ready(user).deliver_later
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
      call = Attachments::CreateService
        .bypass_whitelist(user:)
        .call(container: backup, filename: file_name, file:, description: 'OpenProject backup')

      call.on_success do
        download_url = ::API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(call.result.id)

        upsert_status(
          status: :success,
          message: I18n.t('export.succeeded'),
          payload: download_payload(download_url)
        )
      end

      call.on_failure do
        upsert_status status: :failure,
                      message: I18n.t('export.failed', message: call.message)
      end
    end
  end

  def create_backup_archive!(file_name:, db_dump_file_name:, attachments: attachments_to_include)
    paths_to_clean = []
    clean_up = OpenProject::Configuration.remote_storage?

    Zip::File.open(file_name, Zip::File::CREATE) do |zipfile|
      attachments.each do |attachment|
        path = local_disk_path(attachment)
        next unless path

        zipfile.add "attachment/file/#{attachment.id}/#{attachment[:file]}", path

        paths_to_clean << get_cache_folder_path(attachment) if clean_up && attachment.file.cached?
      end

      zipfile.get_output_stream("openproject.sql") { |f| f.write File.read(db_dump_file_name) }
    end

    remove_paths! paths_to_clean # delete locally cached files that were downloaded just for the backup

    @archived = true

    file_name
  end

  def local_disk_path(attachment)
    # If an attachment is destroyed on disk, skip it
    diskfile = attachment.diskfile
    return unless diskfile

    diskfile.path
  rescue StandardError => e
    Rails.logger.error do
      "Failed to access attachment #{attachment.id} #{attachment.file&.path} for backup: #{e.message}"
    end

    nil
  end

  def remove_paths!(paths)
    paths.each do |path|
      FileUtils.rm_rf path
    end
  end

  def get_cache_folder_path(attachment)
    # expecting paths like /tmp/op_uploaded_files/1639754082-3468-0002-0911/file.ext
    # just making extra sure so we don't delete anything wrong later on
    unless /#{attachment.file.cache_dir}\/[^\/]+\/[^\/]+/.match?(attachment.diskfile.path)
      raise "Unexpected cache path for attachment ##{attachment.id}: #{attachment.diskfile}"
    end

    # returning parent as each cached file is in a separate folder which shall be removed too
    Pathname(attachment.diskfile.path).parent.to_s
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
    msg = I18n.t 'backup.failed'

    upsert_status(
      status: :failure,
      message: error.present? ? "#{msg}: #{error}" : msg
    )
  end
end
