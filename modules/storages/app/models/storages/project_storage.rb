#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

# A ProjectStorage is a kind of relation between a Storage and
# a Project in order to enable or disable a Storage for a specific
# WorkPackages in the project.
# See also: file_link.rb and storage.rb
class Storages::ProjectStorage < ApplicationRecord
  # set table name explicitly (would be guessed from model class name and be
  # project_storages otherwise)
  self.table_name = 'projects_storages'

  # ProjectStorage sits between Project and Storage.
  belongs_to :project, touch: true
  belongs_to :storage, touch: true, class_name: 'Storages::Storage'
  belongs_to :creator, class_name: 'User'

  # There should be only one ProjectStorage per project and storage.
  validates :project, uniqueness: { scope: :storage }
end
