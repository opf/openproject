#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'tempfile'
require 'zip'

class BackupJob < ::ApplicationJob
  queue_with_priority :low

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
    remove_files! db_dump_file_name, archive_file_name

    backup.attachments.each(&:destroy) unless success?

    Rails.logger.info(
      "BackupJob(include_attachments: #{include_attachments}) finished " \
      "with status #{job_status.status} " \
      "(dumped: #{dumped?}, archived: #{archived?})"
    )
  end

  def run_backup!
    @dumped = dump_database! db_dump_file_name # sets error on failure

    return unless dumped?

    file_name = create_backup_archive!(
      file_name: archive_file_name,
      db_dump_file_name: db_dump_file_name
    )

    store_backup file_name, backup: backup, user: user
    cleanup_previous_backups!

    UserMailer.backup_ready(user).deliver_later
  end

  def dumped?
    @dumped
  end

  def archived?
    @archived
  end

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
      FileUtils.rm file if File.exists? file
    end
  end

  def store_backup(file_name, backup:, user:)
    File.open(file_name) do |file|
      attachment = Attachments::CreateService
        .new(backup, author: user)
        .call(uploaded_file: file, description: 'OpenProject backup')

      download_url = ::API::V3::Utilities::PathHelper::ApiV3Path.attachment_content(attachment.id)

      upsert_status(
        status: :success,
        message: I18n.t('export.succeeded'),
        payload: download_payload(download_url)
      )
    end
  end

  def create_backup_archive!(file_name:, db_dump_file_name:, attachments: attachments_to_include)
    Zip::File.open(file_name, Zip::File::CREATE) do |zipfile|
      attachments.each do |attachment|
        # If an attachment is destroyed on disk, skip i
        diskfile = attachment.diskfile
        next unless diskfile

        path = diskfile.path

        zipfile.add "attachment/file/#{attachment.id}/#{attachment[:file]}", path
      end

      zipfile.get_output_stream("openproject.sql") { |f| f.write File.read(db_dump_file_name) }
    end

    @archived = true

    file_name
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
    _out, err, st = Open3.capture3 pg_env, "pg_dump -x -O -f '#{path}'"

    failure! error: err unless st.success?

    st.success?
  end

  def success!
    payload = download_payload(url_helpers.backups_path(target_project))

    if errors.any?
      payload[:errors] = errors
    end

    upsert_status status: :success,
                  message: I18n.t('copy_project.succeeded', target_project_name: target_project.name),
                  payload: payload
  end

  def failure!(error: nil)
    msg = I18n.t 'backup.failed'

    upsert_status(
      status: :failure,
      message: error.present? ? "#{msg}: #{error}" : msg
    )
  end

  def pg_env
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    entries = pg_env_to_connection_config.map do |key, config_key|
      value = config[config_key].to_s

      [key.to_s, value] if value.present?
    end

    entries.compact.to_h
  end

  ##
  # Maps the PG env variable name to the key in the AR connection config.
  def pg_env_to_connection_config
    {
      PGHOST: :host,
      PGPORT: :port,
      PGUSER: :username,
      PGPASSWORD: :password,
      PGDATABASE: :database
    }
  end
end
