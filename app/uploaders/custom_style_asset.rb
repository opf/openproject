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

class CustomStyleAsset
  REVISION_PREFIX = /\A[0-9a-f]{24}~/

  attr_reader :mounted_as

  def initialize(model, field)
    @model = model
    @mounted_as = field
  end

  def assign(input)
    return if input == ""

    cached = cache(input) if input
    @cached&.delete
    @cached = cached
    @pending = true
    @download_key = nil
    @assignment = Object.new
  end

  def identifier
    @pending ? @cached&.original_filename : @model[mounted_as]
  end

  def filename
    identifier&.sub(REVISION_PREFIX, "")
  end

  def file
    @pending ? @cached : reference(@model[mounted_as])
  end

  delegate :blank?, to: :filename

  def readable?
    file&.exists? || false
  rescue Aws::S3::Errors::Forbidden
    false
  end

  def remote?
    file&.storage.is_a?(Shrine::Storage::S3)
  end

  def response_body
    source = file
    Enumerator.new do |body|
      source.open(rewindable: false) { |io| io.each_chunk { |chunk| body << chunk } }
    end
  end

  def local_path
    return unless readable?

    source = file
    if source.storage.is_a?(Shrine::Storage::FileSystem)
      source.storage.path(source.id).to_s
    else
      download(source).path
    end
  end

  def local_file
    path = local_path
    File.open(path, "rb") if path
  end

  def write_identifier
    return unless @pending

    @old = current_reference
    name = @cached&.original_filename
    name = revision_name(name) if name && @model.persisted?
    @model.public_send("#{mounted_as}_will_change!")
    @model[mounted_as] = name
  end

  def store
    return unless @pending

    cached = @cached
    target = reference(@model[mounted_as])
    transaction = @model.class.current_transaction
    old = @old
    restore_on_rollback(transaction, target, cached, @assignment)
    if cached
      AttachmentShrine.upload(cached, :store, location: target.id, metadata: cached.metadata)
    end
    transaction.after_commit do
      cached&.delete
      old&.delete
    end
    @pending = false
    @cached = nil
  end

  def schedule_deletion(identifier)
    stored = reference(identifier)
    cached = @cached
    @model.class.current_transaction.after_commit do
      stored&.delete
      cached&.delete
    end
  end

  private

  def download(source)
    return @download if @download_key == source.id && @download && !@download.closed?

    @download = source.download(rewindable: false)
    @download_key = source.id
    if Rails.application.executor.active?
      (ActiveSupport::IsolatedExecutionState[AttachmentFile::DOWNLOADS_KEY] ||= []) << @download
    end
    @download
  end

  def restore_on_rollback(transaction, target, cached, assignment)
    transaction.after_rollback do
      target&.delete
      if @assignment == assignment
        @cached = cached
        @pending = true
      else
        cached&.delete
      end
    end
  end

  def current_reference
    return unless @model.persisted?

    reference(@model.class.lock.where(id: @model.id).pick(mounted_as))
  end

  def cache(input)
    name = input.respond_to?(:original_filename) ? input.original_filename : File.basename(input.path)
    name = AttachmentShrine.sanitize_filename(name)
    io = input.respond_to?(:tempfile) ? input.tempfile : input
    io.rewind
    mime_type = Marcel::MimeType.for(io, name: name)
    AttachmentShrine.upload(io, :cache, close: false, location: "#{SecureRandom.uuid}/#{name}",
                                        metadata: { "filename" => name, "mime_type" => mime_type })
  end

  def reference(name)
    return unless name.present? && @model.id

    AttachmentShrine.uploaded_file("id" => "custom_style/#{mounted_as}/#{@model.id}/#{File.basename(name)}",
                                   "storage" => "store", "metadata" => metadata(name))
  end

  def revision_name(name)
    prefix = "#{SecureRandom.hex(12)}~"
    extension = File.extname(name)
    budget = 255 - prefix.bytesize
    suffix = extension.truncate_bytes(budget, omission: "")
    stem = name.delete_suffix(extension).truncate_bytes(budget - suffix.bytesize, omission: "")
    "#{prefix}#{stem}#{suffix}"
  end

  def metadata(name)
    { "filename" => name.sub(REVISION_PREFIX, ""), "mime_type" => Marcel::MimeType.for(name: name) }
  end
end
