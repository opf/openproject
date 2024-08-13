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

module Storages
  StorageFileInfo = Data.define(
    :status,
    :status_code,
    :id,
    :name,
    :last_modified_at,
    :created_at,
    :mime_type,
    :size,
    :owner_name,
    :owner_id,
    :last_modified_by_name,
    :last_modified_by_id,
    :permissions,
    :location
  ) do
    def initialize(
      status:,
      status_code:,
      id:,
      name: nil,
      last_modified_at: nil,
      created_at: nil,
      mime_type: nil,
      size: nil,
      owner_name: nil,
      owner_id: nil,
      last_modified_by_name: nil,
      last_modified_by_id: nil,
      permissions: nil,
      location: nil
    )
      super
    end

    def clean_location
      return if location.nil?

      if location.starts_with? "/"
        CGI.unescape(location)
      else
        CGI.unescape("/#{location}")
      end
    end

    def self.from_id(file_id)
      new(id: file_id, status: "OK", status_code: 200)
    end
  end
end
