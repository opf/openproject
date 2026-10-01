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

require "fog/aws"
require "carrierwave"
require "carrierwave/storage/fog"

module CarrierWave
  module Configuration
    def self.configure_fog!(credentials: OpenProject::Configuration.fog_credentials,
                            directory: OpenProject::Configuration.fog_directory,
                            public: false)

      # Ensure that the provider AWS is uppercased
      provider = credentials[:provider] || "AWS"
      if [:aws, "aws"].include? provider
        credentials[:provider] = "AWS"
      end

      # make sure larger attachments are uploaded via multi-part to support
      # files bigger than 4GB (most likely backups) being uploaded from workers
      credentials = { max_put_chunk_size: 100.megabytes }.merge(credentials)

      CarrierWave.configure do |config|
        config.fog_credentials = credentials
        config.fog_directory   = directory
        config.fog_public      = public

        config.use_action_status = true
      end
    end
  end
end

# CW 2.0 changed the default cache_storage from :file to nil.
# Restore :file to keep Attachment.clean_cached_files! working.
CarrierWave.configure do |config|
  config.cache_storage = :file
end

# Keep CarrierWave's workfile staging dir on the same filesystem as FileUploader.cache_dir
# (Dir.tmpdir/op_uploaded_files) and as tempfiles created elsewhere (e.g. BackupJob), so that
# moving a freshly created large file into the cache (see FogFileUploader#move_to_cache) is a
# fast rename instead of a full copy across filesystems.
CarrierWave.tmp_path = File.join(Dir.tmpdir, "carrierwave")

unless OpenProject::Configuration.fog_credentials.empty?
  CarrierWave::Configuration.configure_fog!
end
