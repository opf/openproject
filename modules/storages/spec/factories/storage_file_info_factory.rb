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

FactoryBot.define do
  factory :storage_file_info, class: "::Storages::StorageFileInfo" do
    status { "OK" }
    status_code { 200 }
    sequence(:id) { |n| "20000#{n}" } # rubocop:disable FactoryBot/IdSequence
    sequence(:name) { |n| "file_name_#{n}.txt" }
    last_modified_at { Time.zone.now }
    created_at { Time.zone.now }
    mime_type { "text/plain" }
    sequence(:size) { |n| n * 123 }
    owner_name { "Peter Pan" }
    owner_id { "peter" }
    last_modified_by_name { "Petra Panadera" }
    last_modified_by_id { "petra" }
    permissions { "RMGDNVCK" }
    sequence(:location) { |n| "files/peter/file_name_#{n}.txt" }

    initialize_with do
      new(status, status_code, id, name, last_modified_at, created_at, mime_type, size, owner_name, owner_id,
          last_modified_by_name, last_modified_by_id, permissions, location)
    end
  end
end
