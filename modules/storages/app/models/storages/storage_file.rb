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

module Storages
  StorageFile = Data.define(
    :id,
    :name,
    :size, # Integer >= 0
    :mime_type,
    :created_at, # Time? DateTime (deprecated)?
    :last_modified_at, # Time? DateTime (deprecated)?
    :created_by_name,
    :last_modified_by_name,
    :location, # Should always start with a '/'
    :permissions # Array can be empty or nil
  ) do
    def initialize(
      id:,
      name:,
      size: nil,
      mime_type: nil,
      created_at: nil,
      last_modified_at: nil,
      created_by_name: nil,
      last_modified_by_name: nil,
      location: nil,
      permissions: nil
    )
      super
    end

    def folder?
      mime_type.present? && mime_type == "application/x-op-directory"
    end
  end
end
