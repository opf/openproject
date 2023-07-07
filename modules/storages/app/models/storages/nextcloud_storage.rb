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
  store_accessor :provider_fields,
                 %i[username
                    password
                    group
                    group_folder
                    has_managed_project_folders]

  alias_method :has_managed_project_folders?, :has_managed_project_folders

  def self.sync_all_group_folders
    # Returns false if lock cannot be acquired, block is not executed then.
    OpenProject::Mutex.with_advisory_lock(self,
                                          'sync_all_group_folders',
                                          timeout_seconds: 0,
                                          transaction: false) do
      where("provider_fields->>'has_managed_project_folders' = 'true'")
        .includes(:oauth_client)
        .each do |storage|
        Storages::GroupFolderPropertiesSyncService.new(storage).call
      end
      true
    end
  end

  def group
    super || "OpenProject"
  end

  def group_folder
    super || "OpenProject"
  end

  def username
    super || "OpenProject"
  end

  def has_managed_project_folders=(value)
    super(!!value)
  end

  # rubocop:disable Naming/PredicateName
  def has_managed_project_folders
    !!super
  end
  # rubocop:enable Naming/PredicateName
end
