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

class AttachmentFile
  DOWNLOADS_KEY = :shrine_attachment_downloads

  def self.discard_downloads
    ActiveSupport::IsolatedExecutionState.delete(DOWNLOADS_KEY)&.each(&:close!)
  end

  attr_reader :model

  def initialize(model)
    @model = model
  end

  def assign(input, filename:)
    previous = @cached
    name = AttachmentShrine.sanitize_filename(filename)
    metadata = { "filename" => name, "size" => model.filesize, "mime_type" => model.content_type }
    options = { move: input.is_a?(FogFileUploader::MovableSource) }
    File.open(input.path, "rb") do |source|
      @cached = AttachmentShrine.upload(source, :cache, location: "#{SecureRandom.uuid}/#{name}",
                                                        metadata:, upload_options: options)
    end
    @latest_assignment = @cached.id
    previous&.delete
  end

  def write_identifier
    return unless @cached

    capture_previous_file if model.persisted?
    model[:file] = @cached.original_filename
  end

  def persist
    return unless @cached

    cached = @cached
    reference = next_reference
    register_storage_callbacks(reference, @previous_file, cached)
    stored = AttachmentShrine.upload(cached, :store, location: reference.id)
    model.update_column(:file_data, stored.data)
    @cached = nil
  end

  def filename
    @cached&.original_filename || model[:file]
  end
  alias_method :name, :filename

  def path
    return unless uploaded

    storage = uploaded.storage
    storage.is_a?(Shrine::Storage::S3) ? storage.object(uploaded.id).key : storage.path(uploaded.id).to_s
  end

  def local_file
    return unless uploaded

    if external_storage?
      uploaded.download(rewindable: false).tap do |download|
        if Rails.application.executor.active?
          (ActiveSupport::IsolatedExecutionState[DOWNLOADS_KEY] ||= []) << download
        end
      end
    elsif File.file?(path)
      File.open(path, "rb")
    end
  end

  def external_storage?
    uploaded && uploaded.storage.is_a?(Shrine::Storage::S3)
  end

  def readable?
    uploaded&.exists? || false
  rescue Aws::S3::Errors::Forbidden
    false
  end

  def read
    uploaded&.open(&:read)
  end

  def stream_to(output)
    uploaded.stream(output, **(external_storage? ? { rewindable: false } : {}))
  end

  def copy_to_storage(storage)
    source = uploaded
    return false unless source&.exists?

    source.open { |io| storage.upload(io, source.id, shrine_metadata: source.metadata) }
    true
  end

  def copy_to(attachment)
    io = local_file
    attachment.assign_file(io, filename:)
  ensure
    io.is_a?(Tempfile) ? io.close! : io&.close
  end

  def download_url(options = {})
    return path.to_s unless external_storage?

    expires = (options[:expires_in] || 600).to_i
    uploaded.url(expires_in: [expires, OpenProject::Configuration.fog_download_url_expires_in].min,
                 response_content_disposition: options[:content_disposition],
                 response_content_type: options[:content_type])
  end

  def archive_path
    persisted_reference.id
  end

  def prepare_carrierwave_rollback!
    model.with_lock do
      return unless model.file_data

      current = persisted_reference
      legacy = reference_for(model[:file])
      copy_verified(current, legacy) if current.id != legacy.id
      verify_legacy_file!(legacy)
      model.update_column(:file_data, nil)
    end
  end

  def delete
    @cached&.delete
    persisted_reference&.delete
  end

  private

  def uploaded
    @cached || persisted_reference
  end

  def persisted_reference
    stored_reference(model[:file])
  end

  def capture_previous_file
    current = model.class.lock.select(:id, :file, :file_data).find(model.id)
    @previous_file = stored_reference(current[:file], current.file_data)
    # Another writer may have changed a column that equals this instance's original value.
    %i[file filesize content_type charset digest].each { |attribute| model.public_send("#{attribute}_will_change!") }
  end

  def stored_reference(name, data = model.file_data)
    return unless name.present? && model.id

    if data&.dig("metadata", "filename") == name
      AttachmentShrine.uploaded_file(data)
    else
      reference_for(name)
    end
  end

  def register_storage_callbacks(reference, old, cached)
    transaction = model.class.current_transaction
    transaction.after_rollback do
      reference.delete
      @latest_assignment == cached.id ? @cached = cached : cached.delete
    end

    transaction.after_commit do
      cached.delete
      old&.delete
    end
  end

  def next_reference
    return reference_for(model[:file]) unless @previous_file

    AttachmentRevisionLock.acquire(model.id)
    reference_for(model[:file], directory: "attachment/revisions/#{model.id}/#{SecureRandom.uuid}")
  end

  def copy_verified(current, legacy)
    current.open do |bytes|
      AttachmentShrine.upload(bytes, :store, location: legacy.id, metadata: current.metadata)
    end
    raise IOError, "Failed to verify attachment #{model.id}" unless fingerprint(current) == fingerprint(legacy)
  end

  def verify_legacy_file!(legacy)
    size, md5 = fingerprint(legacy, Digest::MD5.new)
    return if size == model.filesize && (model.digest.blank? || md5 == model.digest)

    raise IOError, "File size or digest differs for attachment #{model.id}"
  end

  def fingerprint(file, digest = Digest::SHA256.new)
    size = 0
    file.open do |io|
      while (chunk = io.read(1024 * 1024))
        digest << chunk
        size += chunk.bytesize
      end
    end
    [size, digest.hexdigest]
  end

  def reference_for(name, directory: "attachment/file/#{model.id}")
    AttachmentShrine.uploaded_file("id" => "#{directory}/#{File.basename(name)}",
                                   "storage" => "store",
                                   "metadata" => { "filename" => name, "size" => model.filesize,
                                                   "mime_type" => model.content_type })
  end
end
