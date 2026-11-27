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

# From the repository root: bundle exec ruby script/spikes/shrine_backup_restore.rb [--legacy|--s3]
# --s3 uses SHRINE_TEST_S3_ENDPOINT, SHRINE_TEST_S3_KEY and SHRINE_TEST_S3_SECRET.
require "tmpdir"
require "fileutils"
require "securerandom"
require "digest"
require "bundler"

FILES = { "carrierwave.bin" => "original CarrierWave\x00\xff".b,
          "shrine.bin" => "new Shrine\x00\xfe".b }.freeze

LEGACY_REVISION = "d0a5c04fa3eb8fc2157653b54f7610b9fc9d59fd"

def expected_files
  ENV["LEGACY_ARCHIVE"] == "1" ? FILES.slice("carrierwave.bin") : FILES
end

def with_database(name)
  system("createdb", name, exception: true)
  begin
    yield
  ensure
    system("dropdb", name, exception: true)
  end
end

def s3_options
  { endpoint: ENV.fetch("SHRINE_TEST_S3_ENDPOINT"), region: "us-east-1", force_path_style: true,
    access_key_id: ENV.fetch("SHRINE_TEST_S3_KEY"), secret_access_key: ENV.fetch("SHRINE_TEST_S3_SECRET") }
end

def with_source_bucket
  return yield(nil) unless ARGV == ["--s3"]

  require "aws-sdk-s3"
  bucket = Aws::S3::Resource.new(**s3_options).bucket("shrine-restore-#{SecureRandom.hex(10)}")
  bucket.client.create_bucket(bucket: bucket.name)
  begin
    yield(bucket.name)
    verify_source_objects(bucket)
  ensure
    bucket.objects.batch_delete!
    bucket.delete
  end
end

def verify_source_objects(bucket)
  keys = bucket.objects.map(&:key)
  %w[uploads/attachment/file/1/carrierwave.bin uploads/attachment/file/2/shrine.bin].each do |key|
    raise "missing expected source object #{key}" unless keys.include?(key)
  end
  puts "S3 source objects: #{keys.sort.join(', ')}"
end

def fog_env(bucket)
  return {} unless bucket

  { "OPENPROJECT_ATTACHMENTS__STORAGE" => "fog", "OPENPROJECT_FOG_DIRECTORY" => bucket,
    "OPENPROJECT_FOG_CREDENTIALS_PROVIDER" => "AWS", "OPENPROJECT_FOG_CREDENTIALS_PATH__STYLE" => "true",
    "OPENPROJECT_FOG_CREDENTIALS_REGION" => "us-east-1",
    "OPENPROJECT_FOG_CREDENTIALS_ENDPOINT" => s3_options.fetch(:endpoint),
    "OPENPROJECT_FOG_CREDENTIALS_AWS__ACCESS__KEY__ID" => s3_options.fetch(:access_key_id),
    "OPENPROJECT_FOG_CREDENTIALS_AWS__SECRET__ACCESS__KEY" => s3_options.fetch(:secret_access_key) }
end

def bundle_environment(root)
  path = Bundler.settings.path
  { "BUNDLE_GEMFILE" => File.join(root, "Gemfile"),
    "BUNDLE_PATH" => (File.expand_path(path.base_path) unless path.use_system_gems?) }
end

def rails_process(phase, database, directory, root: Dir.pwd, bucket: nil)
  env = {
    "DATABASE_URL" => "postgresql:///#{database}", "RAILS_ENV" => "test",
    "LEGACY_ARCHIVE" => ENV.fetch("LEGACY_ARCHIVE"),
    "TEST_ENV_NUMBER" => "4273", "DISABLE_SPRING" => "1", "RESTORE_WORK" => directory,
    "OPENPROJECT_ATTACHMENTS__STORAGE" => "file",
    "OPENPROJECT_ATTACHMENTS__STORAGE__PATH" => File.join(directory, phase == "restored" ? "restored" : "source")
  }
  env.merge!(bundle_environment(root), fog_env(bucket))
  Bundler.with_unbundled_env do
    system(env, RbConfig.ruby, File.expand_path(__FILE__), phase, database, chdir: root, exception: true)
  end
end

def source_root(dir)
  root = File.join(dir, "carrierwave-release")
  FileUtils.mkdir(root)
  archive = File.join(dir, "carrierwave-release.tar")
  system("git", "archive", "-o", archive, LEGACY_REVISION, exception: true)
  system("tar", "-xf", archive, "-C", root, exception: true)
  File.unlink(archive)
  env = bundle_environment(root).merge("BUNDLE_FROZEN" => "true")
  Bundler.with_unbundled_env do
    unless system(env, "bundle", "check", chdir: root, out: File::NULL)
      system(env, "bundle", "install", chdir: root, exception: true)
    end
  end
  root
end

def round_trip
  name = "shrine_restore_4273_#{SecureRandom.hex(5)}"
  Dir.mktmpdir("shrine-restore-") do |dir|
    root = source_root(dir)
    with_database("#{name}_src") do
      with_source_bucket do |bucket|
        rails_process("legacy_source", "#{name}_src", dir, root:, bucket:)
        rails_process("mixed_source", "#{name}_src", dir, bucket:) unless ENV["LEGACY_ARCHIVE"] == "1"
      end
    end
    FileUtils.rm_rf(File.join(dir, "source"))
    with_database("#{name}_dst") do
      system("psql", "-Xq", "-v", "ON_ERROR_STOP=1", "-d", "#{name}_dst", "-f", File.join(dir, "openproject.sql"),
             out: File::NULL, exception: true)
      rails_process("restored", "#{name}_dst", dir)
    end
  end
end

def seed_file(directory, name, author, container)
  path = File.join(directory, name)
  File.binwrite(path, FILES.fetch(name))
  row = File.open(path, "rb") { |input| Attachment.create!(author:, container:, file: input) }
  FileUtils.rm_f(path)
  row.reload
end

def create_backup(user)
  backup = Backup.create!
  job = BackupJob.new(backup:, user:, include_attachments: true)
  job.perform_now
  raise "backup failed: #{job.job_status&.message}" unless job.success?

  backup.attachments.sole
end

def extract_archive(archive, directory, names)
  Zip::File.open(archive.local_path) do |zip|
    entries = zip.entries.map(&:name)
    raise "unexpected archive entries: #{entries}" unless entries.sort == (names.keys + ["openproject.sql"]).sort

    zip.extract("openproject.sql", destination_directory: directory)
    extract_attachments(zip, File.join(directory, "restored"), names)
    puts "BackupJob ZIP: #{entries.join(', ')}"
  end
end

def extract_attachments(zip, restored, names)
  names.each do |entry, filename|
    raise "archive bytes differ for #{entry}" unless zip.read(entry).b == FILES.fetch(filename)

    FileUtils.mkdir_p(File.dirname(File.join(restored, entry)))
    zip.extract(entry, destination_directory: restored)
  end
end

def migrate
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Base.connection_pool.migration_context.migrate
  Attachment.reset_column_information
end

def legacy_source(directory)
  migrate
  raise "legacy database already migrated" if Attachment.column_names.include?("file_data")

  user = User.create!(admin: true, login: "restore-admin", mail: "restore@example.org",
                      firstname: "Restore", lastname: "Check", status: :active)
  User.current = user
  container = AttributeHelpText::WorkPackage.create!(help_text: "Example", attribute_name: "status")
  row = seed_file(directory, "carrierwave.bin", user, container)
  raise "expected a CarrierWave writer" unless row.file.is_a?(OpenProject::Configuration.file_uploader)

  backup_and_extract(directory, user, container) if ENV["LEGACY_ARCHIVE"] == "1"
end

def mixed_source(directory)
  migrate
  user = User.find_by!(login: "restore-admin")
  User.current = user
  container = AttributeHelpText::WorkPackage.sole
  raise "expected a legacy reference" unless Attachment.sole.file_data.nil?

  row = seed_file(directory, "shrine.bin", user, container)
  raise "new row lacks Shrine metadata" if row.file_data.blank?

  backup_and_extract(directory, user, container)
end

def backup_and_extract(directory, user, container)
  names = Attachment.where(container:).to_h { |row| ["attachment/file/#{row.id}/#{row.filename}", row.filename] }
  extract_archive(create_backup(user), directory, names)
end

def verify_content_response(session, row, headers, expected)
  session.get("/api/v3/attachments/#{row.id}/content", headers:)
  response = session.response
  raise "API returned #{response.status}: #{response.body.first(300)}" unless response.status == 200
  raise "API bytes differ: #{row.filename}" unless response.body.b == expected

  puts "#{row.filename}: HTTP 200, #{expected.bytesize} bytes, SHA-256 #{Digest::SHA256.hexdigest(expected)}"
end

def authorization_headers
  user = User.find_by!(login: "restore-admin")
  token = Token::API.create!(user:, token_name: "restore-check")
  { "Authorization" => "Bearer #{token.plain_value}" }
end

def migrate_legacy_restore
  raise "restored SQL already migrated" if Attachment.column_names.include?("file_data")

  migrate
end

def restored_attachment(filename, expected)
  row = Attachment.find_by!(file: filename)
  raise "wrong storage metadata: #{filename}" unless row.file_data.present? == (filename == "shrine.bin")
  raise "restored bytes differ: #{filename}" unless File.binread(row.local_path) == expected

  row
end

def verify_restored
  migrate_legacy_restore if ENV["LEGACY_ARCHIVE"] == "1"
  headers = authorization_headers
  session = ActionDispatch::Integration::Session.new(Rails.application)
  session.host! Setting.host_name
  expected_files.each do |filename, expected|
    row = restored_attachment(filename, expected)
    verify_content_response(session, row, headers, expected)
  end
end

if ARGV.empty? || [%w[--legacy], %w[--s3]].include?(ARGV)
  ENV["LEGACY_ARCHIVE"] = ARGV == ["--legacy"] ? "1" : "0"
  round_trip
else
  require File.expand_path("config/environment")
  phase, database = ARGV
  raise "unexpected database" unless Rails.env.test? && ActiveRecord::Base.connection_db_config.database == database &&
                                    database.match?(/\Ashrine_restore_4273_[a-z0-9]+_(src|dst)\z/)

  directory = ENV.fetch("RESTORE_WORK")
  storage = Pathname(directory).join(phase == "restored" ? "restored" : "source")
  raise "unexpected storage path" unless OpenProject::Configuration.attachments_storage_path == storage

  case phase
  when "legacy_source" then legacy_source(directory)
  when "mixed_source" then mixed_source(directory)
  when "restored" then verify_restored
  else raise "unknown phase: #{phase}"
  end
end
