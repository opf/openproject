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

require 'fileutils'

class LocalFileUploader < CarrierWave::Uploader::Base
  include FileUploader
  storage :file

  # Delete cache and old rack file after store
  # cf. https://github.com/carrierwaveuploader/carrierwave/wiki/How-to:-Delete-cache-garbage-directories

  before :store, :remember_cache_id
  after :store, :delete_tmp_dir
  after :store, :delete_old_tmp_file

  def copy_to(attachment)
    attachment.file = local_file
  end

  def store_dir
    dir = "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    OpenProject::Configuration.attachments_storage_path.join(dir)
  end
end
