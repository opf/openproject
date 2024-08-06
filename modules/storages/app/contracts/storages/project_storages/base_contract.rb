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

# A "contract" is an OpenProject pattern used to validate parameters
# before actually creating, updating, or deleting a model.
# Used by: project_storages_controller.rb and in the API
module Storages::ProjectStorages
  class BaseContract < ::ModelContract
    # "Concern" just injects a permission checking routine.
    # Not sure where this concern is reused.
    include ::Storages::ProjectStorages::Concerns::ManageStoragesGuarded
    # Include validation library
    include ActiveModel::Validations

    attribute :project
    validates_presence_of :project
    attribute :storage
    validates_presence_of :storage
    attribute :project_folder_mode
    validates :project_folder_mode, presence: true, inclusion: { in: Storages::ProjectStorage.project_folder_modes.keys }
    attribute :project_folder_id
    validates :project_folder_id, presence: true, if: :project_folder_mode_manual?

    attribute :project_folder_mode do
      if Storages::ProjectStorage.project_folder_modes.keys.exclude?(@model.project_folder_mode)
        errors.add :project_folder_mode, :invalid
      end
    end

    validate :project_folder_mode_available_for_storage, unless: -> { errors.include?(:project_folder_mode) }

    private

    def project_folder_mode_manual?
      @model.project_folder_manual?
    end

    def project_folder_mode_available_for_storage
      if storage&.available_project_folder_modes&.exclude?(@model.project_folder_mode)
        errors.add :project_folder_mode, :mode_unavailable
      end
    end
  end
end
