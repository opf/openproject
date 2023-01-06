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

# A "Storage" refers to some external source where files are stored.
# The first supported storage is Nextcloud (www.nextcloud.com).
# a Storage is mainly defined by a name, a "provider_type" (i.e.
# Nextcloud or something similar) and a "host" URL.
#
# Purpose: The code below is a standard Ruby model:
# https://guides.rubyonrails.org/active_model_basics.html
# It defines defines checks and permissions on the Ruby level.
# Additional attributes and constraints are defined in
# db/migrate/20220113144323_create_storage.rb "migration".
class Storages::Storage < ApplicationRecord
  # One Storage can have multiple FileLinks, representing external files.
  #
  # FileLink deletion is done:
  #   - through a on_delete: :cascade at the database level when deleting a
  #     Storage
  #   - through a before_destroy hook at the application level when deleting a
  #     ProjectStorage
  has_many :file_links, class_name: 'Storages::FileLink'
  # Basically every OpenProject object has a creator
  belongs_to :creator, class_name: 'User'
  # A project manager can enable/disable Storages per project.
  has_many :projects_storages, dependent: :destroy, class_name: 'Storages::ProjectStorage'
  # We can get the list of projects with this Storage enabled.
  has_many :projects, through: :projects_storages
  # The OAuth client credentials that OpenProject will use to obtain user specific
  # access tokens from the storage server, i.e a Nextcloud serer.
  has_one :oauth_client, as: :integration, dependent: :destroy
  has_one :oauth_application, class_name: '::Doorkeeper::Application', as: :integration, dependent: :destroy

  PROVIDER_TYPES = [
    PROVIDER_TYPE_NEXTCLOUD = 'nextcloud'.freeze
  ].freeze

  # Uniqueness - no two storages should  have the same host.
  validates_uniqueness_of :host
  validates_uniqueness_of :name

  # Creates a scope of all storages, which belong to a project the user is a member
  # and has the permission ':view_file_links'
  scope :visible, ->(user = User.current) {
    if user.allowed_to_globally?(:manage_storages_in_project)
      all
    else
      where(
        projects_storages: ::Storages::ProjectStorage.where(
          project: Project.allowed_to(user, :view_file_links)
        )
      )
    end
  }
end
