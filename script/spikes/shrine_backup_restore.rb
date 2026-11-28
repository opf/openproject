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

BRANDING_FIXTURE = "spec/fixtures/files/icon_logo.svg"
REPLACEMENT = "committed replacement\x00\xfc".b.freeze
LEGACY_REVISION = "d0a5c04fa3eb8fc2157653b54f7610b9fc9d59fd"

def expected_files
  ENV["LEGACY_ARCHIVE"] == "1" ? FILES.slice("carrierwave.bin") : FILES.merge("shrine.bin" => REPLACEMENT)
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

def with_bucket
  return yield(nil) unless ARGV == ["--s3"]

  require "aws-sdk-s3"
  bucket = Aws::S3::Resource.new(**s3_options).bucket("shrine-restore-#{SecureRandom.hex(10)}")
  bucket.client.create_bucket(bucket: bucket.name)
  begin
    yield(bucket)
  ensure
    bucket.objects.batch_delete!
    bucket.delete
  end
end

def fog_env(bucket)
  return {} unless bucket

  { "OPENPROJECT_ATTACHMENTS__STORAGE" => "fog", "OPENPROJECT_FOG_DIRECTORY" => bucket.name,
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

def process_environment(phase, database, directory, root, bucket)
  env = {
    "DATABASE_URL" => "postgresql:///#{database}", "RAILS_ENV" => "test",
    "LEGACY_ARCHIVE" => ENV.fetch("LEGACY_ARCHIVE"), "TMPDIR" => directory,
    "TEST_ENV_NUMBER" => "4273", "DISABLE_SPRING" => "1", "RESTORE_WORK" => directory,
    "OPENPROJECT_ATTACHMENTS__STORAGE" => "file",
    "OPENPROJECT_ATTACHMENTS__STORAGE__PATH" => File.join(directory, phase == "restored" ? "restored" : "source")
  }
  env.merge(bundle_environment(root), fog_env(bucket))
end

def rails_process(phase, database, directory, root: Dir.pwd, bucket: nil)
  env = process_environment(phase, database, directory, root, bucket)
  Bundler.with_unbundled_env do
    if phase == "prepare_rollback"
      system(env, "bundle", "exec", "rake", "attachments:prepare_carrierwave_rollback", chdir: root, exception: true)
    else
      crash = phase.start_with?("kill_")
      system(env, RbConfig.ruby, File.expand_path(__FILE__), phase, database, chdir: root, exception: !crash)
      if crash
        raise "#{phase}: expected SIGKILL, got #{$?}" if $?.termsig != Signal.list.fetch("KILL")

        puts "#{phase}: worker terminated by SIGKILL"
      end
    end
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
      with_bucket do |bucket|
        rails_process("legacy_source", "#{name}_src", dir, root:, bucket:)
        exercise_replacement("#{name}_src", dir, root, bucket) unless ENV["LEGACY_ARCHIVE"] == "1"
      end
    end
    FileUtils.rm_rf(File.join(dir, "source"))
    verify_restore("#{name}_dst", dir)
  end
end

def verify_restore(database, dir)
  with_database(database) do
    system("psql", "-Xq", "-v", "ON_ERROR_STOP=1", "-d", database, "-f", File.join(dir, "openproject.sql"),
           out: File::NULL, exception: true)
    with_bucket do |bucket|
      restore_bucket(bucket, dir) if bucket
      rails_process("restored", database, dir, bucket:)
    end
  end
end

def exercise_replacement(database, directory, legacy_root, bucket)
  %w[mixed_source kill_before_commit verify_before_commit kill_after_commit backup_after_commit].each do |phase|
    rails_process(phase, database, directory, bucket:)
  end
  rails_process("prepare_rollback", database, directory, bucket:)
  rails_process("legacy_rollback", database, directory, root: legacy_root, bucket:)
end

def restore_bucket(bucket, directory)
  restored = File.join(directory, "restored")
  Dir.glob("**/*", base: restored).each do |entry|
    path = File.join(restored, entry)
    next unless File.file?(path)

    File.open(path, "rb") { |io| bucket.object("uploads/#{entry}").put(body: io) }
  end
  FileUtils.remove_entry(restored)
  puts "Restored S3 bucket #{bucket.name}: #{bucket.objects.map(&:key).sort.join(', ')}"
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
  names.each do |entry, bytes|
    raise "archive bytes differ for #{entry}" unless zip.read(entry).b == bytes

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

  File.open(BRANDING_FIXTURE, "rb") { |input| CustomStyle.create!(logo: input) }
  row = seed_file(directory, "shrine.bin", user, container)
  raise "new row lacks Shrine metadata" if row.file_data.blank?
end

def kill_worker(phase, directory)
  path = File.join(directory, "shrine.bin")
  File.binwrite(path, phase == "kill_before_commit" ? "uncommitted replacement" : REPLACEMENT)
  Attachment.transaction do |transaction|
    transaction.after_commit { Process.kill(:KILL, Process.pid) } if phase == "kill_after_commit"
    replace_and_verify(path)

    Process.kill(:KILL, Process.pid) if phase == "kill_before_commit"
  end
  raise "worker unexpectedly survived"
end

def replace_and_verify(path)
  row = Attachment.find_by!(file: "shrine.bin")
  File.open(path, "rb") { |input| row.update!(file: input) }
  raise "replacement did not promote" unless row.reload.file.read == File.binread(path)
end

def backup_after_commit(directory)
  verify_files(expected_files)
  row = Attachment.find_by!(file: "shrine.bin")
  canonical = "attachment/file/#{row.id}/shrine.bin"
  raise "replacement points at canonical object" if row.file_data.fetch("id") == canonical
  raise "old key already cleaned up" unless AttachmentShrine.storage_for(:store).exists?(canonical)

  user = User.find_by!(login: "restore-admin")
  User.current = user
  backup_and_extract(directory, user, AttributeHelpText::WorkPackage.sole)
end

def backup_and_extract(directory, user, container)
  names = Attachment.where(container:).to_h { |row| [archive_entry(row), expected_files.fetch(row.filename)] }
  if ENV["LEGACY_ARCHIVE"] != "1"
    style = CustomStyle.sole
    names["custom_style/logo/#{style.id}/#{style[:logo]}"] = File.binread(BRANDING_FIXTURE)
  end
  extract_archive(create_backup(user), directory, names)
end

def archive_entry(row)
  (row.file_data&.fetch("id") if row.has_attribute?(:file_data)) || "attachment/file/#{row.id}/#{row.filename}"
end

def verify_content_response(session, row, headers, expected)
  session.get("/api/v3/attachments/#{row.id}/content", headers:)
  response = content_response(session.response, row)
  raise "API bytes differ: #{row.filename}" unless response.body.b == expected

  puts "#{row.filename}: HTTP 200, #{expected.bytesize} bytes, SHA-256 #{Digest::SHA256.hexdigest(expected)}"
end

def content_response(response, row)
  if row.external_storage?
    require "net/http"
    raise "API returned #{response.status}, expected redirect" unless response.redirect?

    response = Net::HTTP.get_response(URI(response.location))
    status = response.code.to_i
  else
    status = response.status
  end
  raise "content response #{status}" unless status == 200

  response
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

def verify_files(files, carrierwave: false)
  headers = authorization_headers
  session = ActionDispatch::Integration::Session.new(Rails.application)
  session.host! Setting.host_name
  files.each do |filename, expected|
    row = Attachment.find_by!(file: filename)
    check_row(row, filename, expected, carrierwave)
    check_public_filename(session, headers, row, filename)

    verify_content_response(session, row, headers, expected)
  end
end

def check_public_filename(session, headers, row, filename)
  session.get("/api/v3/attachments/#{row.id}", headers:)
  raise "attachment API returned #{session.response.status}" unless session.response.successful?
  raise "wrong public API filename" unless JSON.parse(session.response.body).fetch("fileName") == filename
end

def verify_branding
  style = CustomStyle.sole
  raise "wrong branding identifier" unless style[:logo] == File.basename(BRANDING_FIXTURE)
  raise "wrong branding bytes" unless File.binread(style.logo.local_file.path) == File.binread(BRANDING_FIXTURE)

  puts "Verified branding logo #{style[:logo]}"
end

def check_row(row, filename, expected, carrierwave)
  raise "wrong public filename" unless row.filename == filename
  raise "database digest differs" unless row.digest == Digest::MD5.hexdigest(expected)

  check_storage_type(row, filename, carrierwave)
end

def check_storage_type(row, filename, carrierwave)
  if carrierwave
    raise "expected CarrierWave reader" unless row.file.is_a?(OpenProject::Configuration.file_uploader)
    raise "rollback left Shrine metadata" if row.file_data.present?
  else
    expected_metadata = filename == "shrine.bin"
    raise "wrong storage metadata" unless row.file_data.present? == expected_metadata
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
  when "kill_before_commit", "kill_after_commit" then kill_worker(phase, directory)
  when "verify_before_commit" then verify_files(FILES)
  when "backup_after_commit" then backup_after_commit(directory)
  when "legacy_rollback"
    verify_files(expected_files, carrierwave: true)
    verify_branding
  when "restored"
    migrate_legacy_restore if ENV["LEGACY_ARCHIVE"] == "1"
    verify_files(expected_files)
    verify_branding unless ENV["LEGACY_ARCHIVE"] == "1"
  else raise "unknown phase: #{phase}"
  end
end
