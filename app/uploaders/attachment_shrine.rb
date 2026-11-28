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

require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/s3"

class AttachmentShrine < Shrine
  class << self
    def find_storage(name)
      storage_for(name.to_sym)
    end

    def storage_for(name)
      case name
      when :cache
        Shrine::Storage::FileSystem.new(File.join(Dir.tmpdir, "op_shrine_cache"), permissions: 0o600,
                                                                                  directory_permissions: 0o700)
      when :store
        permanent_storage(OpenProject::Configuration.attachments_storage.to_sym)
      when :s3
        s3_storage
      else
        raise Shrine::MissingStorage, name.inspect
      end
    end

    def permanent_storage(backend)
      case backend
      when :file
        Shrine::Storage::FileSystem.new(OpenProject::Configuration.attachments_storage_path)
      when :fog
        s3 = storage_for(:s3)
        Shrine::Storage::S3.new(bucket: s3.bucket.name, client: s3.client, prefix: "uploads")
      else
        raise Shrine::MissingStorage, backend.inspect
      end
    end

    def sanitize_filename(filename)
      name = File.basename(filename.to_s.tr("\\", "/")).gsub(/[^[:word:].+-]/, "_")
      return "unnamed" if name.empty?

      name.match?(/\A\.+\z/) ? "_#{name}" : name
    end

    private

    def s3_storage
      config = OpenProject::Configuration.fog_credentials
      options = {
        bucket: OpenProject::Configuration.fog_directory,
        endpoint: config[:endpoint],
        region: config[:region] || "us-east-1",
        force_path_style: config[:path_style],
        access_key_id: config[:aws_access_key_id],
        secret_access_key: config[:aws_secret_access_key],
        session_token: config[:aws_session_token]
      }.compact
      Shrine::Storage::S3.new(**options)
    end
  end
end
