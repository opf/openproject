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

# A FileLink represents a relation to a single file stored in some cloud file storage.
# Additional attributes and constraints are defined in db/migrate/20220113144759_create_file_links.rb
# FileLinks are attached to a "container", which currently has to be a WorkPackage.
class Storages::FileLink < ApplicationRecord
  belongs_to :storage
  belongs_to :creator, class_name: "User"
  belongs_to :container, polymorphic: true

  validates :container_type, inclusion: { in: ["WorkPackage", nil] }
  validates :origin_id, presence: true

  attr_writer :origin_status

  def origin_status
    @origin_status || nil
  end

  delegate :project, to: :container

  def name
    origin_name
  end
end
