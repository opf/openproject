#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
require 'apartment/migrator'

class RestoreBackupJob < ApplicationJob
  module Schemas
    def default_schema_name
      "public"
    end
  
    def preview_schema_name(backup_id:)
      "backup_preview_#{backup_id}"
    end
  
    def schema_exists?(schema_name)
      query = "SELECT schema_name FROM information_schema.schemata WHERE schema_name = :schema_name"
  
      execute_sql(query, schema_name: schema_name).to_a.map { |row| row["schema_name"] }.first
    end
  
    def create_new_schema!(schema_name)
      execute_sql('CREATE SCHEMA :schema_name', schema_name: schema_name, double_quote: true)
    end
  
    def rename_schema!(from, to)
      execute_sql('ALTER SCHEMA :from RENAME TO :to', from: from, to: to, double_quote: true)
    end
  
    def drop_schema!(schema_name)
      execute_sql('DROP SCHEMA :schema_name CASCADE', schema_name: schema_name, double_quote: true)
    end

    def execute_sql(query, params = {})
      double_quote = params.delete :double_quote
      query = ActiveRecord::Base.sanitize_sql([query, params])
      query = query.gsub("'", '"') if double_quote

      ActiveRecord::Base.connection.execute(query)
    end
  end

  include Schemas
  extend Schemas

  queue_with_priority :high

  attr_reader :backup, :user, :paths_to_clean

  delegate :status, to: :job_status

  def perform(backup:, user:, preview:)
    @backup = backup
    @user = user
    @preview = preview
    @success = false
    @paths_to_clean = []

    attachment = backup.attachments.first

    if attachment.file.cached?
      paths_to_clean << get_cache_folder_path(attachment)
    end

    upsert_status(
      status: :in_process,
      message: I18n.t("#{i18n_key}.restore.job_status.in_process")
    )

    restore_backup!

    @success = true
  rescue StandardError => e
    failure! error: e.message

    Rails.logger.error e
    Rails.logger.error e.backtrace.join("\n")
  ensure
    after_restore
  end

  def status_reference
    arguments.first[:backup]
  end

  def updates_own_status?
    true
  end

  def success?
    job_status.status == JobStatus::Status.statuses[:success]
  end

  def restore_backup!
    restore_backup_into_separate_schema

    if !preview?
      Setting._maintenance_mode = { enabled: true, message: "Backup is being restored" }

      Apartment::Tenant.switch(preview_schema_name) do
        restore_attachments!
      end
    end

    upsert_status status: :success, message: I18n.t("#{i18n_key}.restore.job_status.success")
  end

  def i18n_key
    "backup" + i18n_suffix
  end

  def i18n_suffix
    preview? ? "_preview" : ""
  end

  def self.switch_database_to_restored_backup!(backup_id:)
    ActiveRecord::Base.transaction do
      job = self.new
      job.drop_schema! default_schema_name
      job.rename_schema! preview_schema_name(backup_id: backup_id), default_schema_name
    end
  end

  def restore_backup_into_separate_schema
    if schema_exists? preview_schema_name
      drop_schema! preview_schema_name
    end

    Zip::File.open(backup_file_path) do |zip_file|
      sql_file_entry = zip_file.find_entry "openproject.sql"

      raise "Could not find openproject.sql in backup" if !sql_file_entry

      sql = sql_file_entry.get_input_stream.read
      import_schema = get_current_schema_name sql
      import_sql = normalized_structure sql, schema_name: import_schema, new_schema_name: preview_schema_name

      # make sure we set a search path as to not import into the current schema
      if !import_sql.include?("SET search_path = \"#{preview_schema_name}\";")
        raise "SQL missing search path"
      end

      File.open(db_dump_file_name, "w") do |file|
        file.puts import_sql
      end
    end

    if !File.exist?(db_dump_file_name)
      raise "Failed to write import SQL"
    end

    create_new_schema! preview_schema_name
    restore_database! db_dump_file_name

    Apartment::Migrator.migrate preview_schema_name

    Apartment::Tenant.switch(preview_schema_name) do
      ActiveRecord::Migration.check_pending! # will raise error if there are still migrations pending
    end
  end

  def restore_attachments!
    Zip::File.open(backup_file_path) do |zip_file|
      i = 0
      n = zip_file.entries.size

      zip_file.entries.each do |entry|
        next if entry.name == "openproject.sql"

        upload_file entry, i, n if entry.file?

        i += 1
      end
    end
  end

  def upload_file(entry, i, n)
    attachment_id = entry.name.scan(/file\/(\d+)\//).flatten.first
    attachment = Attachment.find attachment_id
    tmp_dir = Dir.mktmpdir "files"
    file_name = Pathname(entry.name).basename.to_s
    file_path = Pathname(tmp_dir).join(file_name).to_s

    begin
      entry.extract file_path

      attachment.file = File.open file_path
      attachment.save!

      update_upload_status i, n
    ensure
      FileUtils.rm file_path
    end
  end

  def update_upload_status(i, n)
    upsert_status(
      status: :in_process,
      message: I18n.t("backup.restore.job_status.in_process") + " (#{i}/#{n} #{I18n.t('label_attachment_plural')})"
    )
  end

  def get_current_schema_name(sql)
    schemas = sql.scan(/CREATE SCHEMA (.*);/i).flatten.map { |s| s.gsub('"', '').strip.presence }.compact

    if schemas.size > 1
      raise "Expected 1 schema, found #{schemas.size}"
    elsif schemas.size == 1
      schemas.first
    else
      "public"
    end
  end

  def restore_database!(sql_file_path)
    run_command! restore_command(sql_file_path)
  end

  def run_command!(command)
    _out, err, st = Open3.capture3 pg_env, command

    failure! error: err unless st.success?

    st.success?
  end

  def restore_command(sql_file_path)
    "psql -f '#{sql_file_path}'"
  end

  def backup_file_path
    @backup_file_path ||= backup.attachments.first.file.local_file.path
  end

  def normalized_structure(content, schema_name: "public", new_schema_name: nil)
    content
      .then { |s| s.gsub "#{schema_name}.", "" }
      .then { |s| s.gsub /^SET search_path TO.*$/, "" }
      .then { |s| s.gsub /(SET default_table_access_method)/, '-- \1' }
      .then { |s| s.sub /^SELECT pg_catalog\.set_config\('search_path'.*$/, "" }
      .then { |s| s.gsub /^(COMMENT ON)/, '-- \1' }
      .then { |s| s.gsub /^(\s*)(AS integer)/, '\1-- \2' }
      .then { |s| new_schema_name.nil? ? s : s.sub(/^(CREATE .*)$/, "\\1\n\nSET search_path = \"#{new_schema_name}\";") }
  end

  def after_restore
    if !@success
      if schema_exists?(preview_schema_name)
        drop_schema! preview_schema_name
      end
    end

    remove_files! paths_to_clean

    Setting._maintenance_mode = { enabled: false }

    Rails.logger.info(
      "RestoreBackupJob(backup_id: #{backup.id}, preview: #{preview?}) finished " \
      "with status #{status} "
    )
  end

  def get_cache_folder_path(attachment)
    # expecting paths like /tmp/op_uploaded_files/1639754082-3468-0002-0911/file.ext
    # just making extra sure so we don't delete anything wrong later on
    unless attachment.diskfile.path =~ /#{attachment.file.cache_dir}\/[^\/]+\/[^\/]+/
      raise "Unexpected cache path for attachment ##{attachment.id}: #{attachment.diskfile}"
    end

    # returning parent as each cached file is in a separate folder which shall be removed too
    Pathname(attachment.diskfile.path).parent.to_s
  end

  def db_dump_file_name
    @db_dump_file_name ||= tmp_file_name "openproject", ".sql"
  end

  def status_reference
    nil
  end

  def updates_own_status?
    true
  end

  def success?
    job_status.status == JobStatus::Status.statuses[:success]
  end

  def preview?
    @preview
  end

  def remove_files!(*files)
    Array(files).each do |file|
      FileUtils.rm_rf file
    end
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
    unless attachment.diskfile.path =~ /#{attachment.file.cache_dir}\/[^\/]+\/[^\/]+/
      raise "Unexpected cache path for attachment ##{attachment.id}: #{attachment.diskfile}"
    end

    # returning parent as each cached file is in a separate folder which shall be removed too
    Pathname(attachment.diskfile.path).parent.to_s
  end

  def tmp_file_name(name, ext)
    file = Tempfile.new [name, ext]

    file.path
  ensure
    file.close
    file.unlink
  end

  def failure!(error: nil)
    msg = I18n.t 'backup.restore.failed'

    upsert_status(
      status: :failure,
      message: error.present? ? "#{msg}: #{error}" : msg
    )
  end

  def pg_env
    entries = pg_env_to_connection_config.map do |key, config_key|
      possible_keys = Array(config_key)
      value = possible_keys
        .lazy
        .filter_map { |key| database_config[key] }
        .first

      [key.to_s, value.to_s] if value.present?
    end

    entries.compact.to_h
  end

  def database_config
    @database_config ||= ActiveRecord::Base.connection_db_config.configuration_hash
  end

  ##
  # Maps the PG env variable name to the key in the AR connection config.
  def pg_env_to_connection_config
    {
      PGHOST: :host,
      PGPORT: :port,
      PGUSER: %i[username user],
      PGPASSWORD: :password,
      PGDATABASE: :database
    }
  end

  def self.preview_active?(backup_id: nil)
    id = backup_id.present? ? backup_id : '%'
    op = backup_id.present? ? '=' : 'LIKE'
    schema = preview_schema_name backup_id: id
    query = "SELECT schema_name FROM information_schema.schemata WHERE schema_name LIKE '#{schema}';"
  
    ActiveRecord::Base.connection.execute(query).to_a.map { |row| row["schema_name"] }.first
  end

  def self.close_preview!(backup_id: nil)
    preview_schema = preview_active? backup_id: backup_id

    drop_schema! preview_schema
  end
end
