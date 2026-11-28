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

require "shrine/storage/file_system"
require "shrine/storage/s3"

module Attachments
  class PruneRevisions
    PREFIX = "attachment/revisions"
    UUID = /[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/
    REVISION = %r{\A#{PREFIX}/([1-9][0-9]*)/#{UUID}/([[:word:].+-]+)\z}

    def initialize(storage: AttachmentShrine.storage_for(:store), apply: false, output: $stdout)
      @storage = storage
      @apply = apply
      @output = output
    end

    def call
      each_key do |key|
        match = REVISION.match(key)
        next unless match && match[2] == AttachmentShrine.sanitize_filename(match[2])

        prune(key, match[1].to_i)
      end
    end

    private

    def each_key(&)
      case @storage
      when Shrine::Storage::FileSystem
        each_local_key(&)
      when Shrine::Storage::S3
        prefix = "#{@storage.object(PREFIX).key}/"
        @storage.bucket.objects(prefix:).each do |object|
          yield "#{PREFIX}/#{object.key.delete_prefix(prefix)}"
        end
      else
        raise ArgumentError, "Unsupported attachment storage #{@storage.class}"
      end
    end

    def each_local_key
      Dir.glob("#{PREFIX}/**/*", File::FNM_DOTMATCH, base: @storage.directory, sort: false) do |key|
        path = @storage.path(key)
        yield key if !path.symlink? && path.file?
      end
    end

    def prune(key, id)
      Attachment.transaction do
        row = Attachment.where(id:)
        row.lock.pick(:id)
        AttachmentRevisionLock.acquire(id)
        next if Attachment.uncached { row.pick(:file_data)&.dig("id") } == key

        @storage.delete(key) if @apply
        @output.puts("#{@apply ? 'Deleted' : 'Would delete'} #{key}")
      end
    end
  end
end
