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

class Storages::NextcloudStorage < Storages::Storage
  PROVIDER_FIELDS_DEFAULTS = {
    automatically_managed: true,
    username: 'OpenProject'
  }.freeze

  store_accessor :provider_fields,
                 :automatically_managed,
                 :username,
                 :password,
                 :group,
                 :group_folder,
                 :has_managed_project_folders

  # Cast `automatically_managed` provider_field to a primitive boolean value.
  def automatically_managed=(maybe_boolean)
    super(ActiveRecord::Type::Boolean.new.cast(maybe_boolean))
  end

  alias automatically_managed? automatically_managed

  def automatic_management_unspecified?
    automatically_managed.nil?
  end

  def group
    super || PROVIDER_FIELDS_DEFAULTS[:username]
  end

  def group_folder
    super || PROVIDER_FIELDS_DEFAULTS[:username]
  end

  def username
    super || PROVIDER_FIELDS_DEFAULTS[:username]
  end

  def has_managed_project_folders=(value)
    super(!!value)
  end

  def has_managed_project_folders # rubocop:disable Naming/PredicateName
    !!super
  end

  alias has_managed_project_folders? has_managed_project_folders

  def provider_fields_defaults
    PROVIDER_FIELDS_DEFAULTS
  end
end
