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

# A FileLink represents a single file stored in some Storage
# (currently basically a Nextcloud store). Additional attributes
# and constraints are defined in db/migrate/20220113144759_create_file_links.rb
# FileLinks are attached to a "container", which currently has to
# be a WorkPackage.
#
# Purpose: The code below is a standard Ruby model:
# https://guides.rubyonrails.org/active_model_basics.html
# It defines defines checks and permissions on the Ruby level.
# Additional attributes and constraints are defined in
# db/migrate/20220113144759_create_file_links.rb migration.
class Storages::FileLink < ApplicationRecord
  # Every FileLink references its Storage. A "on delete cascade" is defined in
  # the migration, so this FileLink will be deleted when deleting the Storage.
  belongs_to :storage

  # The object who created the FileLink should be of type User.
  belongs_to :creator, class_name: 'User'

  # FileLinks are attached to a container ()currently a WorkPackage)
  # Wieland: This needs to become more flexible in the future
  belongs_to :container, polymorphic: true

  # Currently only WorkPackages are supported as containers for FileLinks
  # For some reason this case is not handled in the belongs_to above.
  validates :container_type, inclusion: { in: ["WorkPackage", nil] }

  # origin_id is the Nextcloud ID of the file and should be valid.
  validates :origin_id, presence: true

  # Is this file shared with me in Nextcloud?
  # This attribute is _not_ to be stored in the DB
  attr_writer :origin_permission

  def origin_permission
    @origin_permission || nil
  end

  delegate :project, to: :container

  def name
    origin_name
  end
end
