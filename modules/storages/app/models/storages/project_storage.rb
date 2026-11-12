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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  class ProjectStorage < ApplicationRecord
    using Peripherals::ServiceResultRefinements

    belongs_to :project, touch: true
    belongs_to :storage, touch: true, class_name: "Storages::Storage"
    belongs_to :creator, class_name: "User"

    has_many :last_project_folders,
             class_name: "Storages::LastProjectFolder",
             dependent: :destroy

    # There should be only one ProjectStorage per project and storage.
    validates :project, uniqueness: { scope: :storage }

    enum :project_folder_mode, {
      inactive: "inactive",
      manual: "manual",
      automatic: "automatic"
    }, prefix: "project_folder"

    scope :automatic, -> { where(project_folder_mode: "automatic") }
    scope :active, -> { joins(:project).where(project: { active: true }) }
    scope :active_automatically_managed, -> do
      automatic
        .active
        .where(storage: Storage.automatic_management_enabled)
    end
    scope :with_project_folder, -> { where.not(project_folder_id: [nil, ""]) }

    def project_folder_mode_possible?(project_folder_mode)
      storage.present? && storage.available_project_folder_modes&.include?(project_folder_mode)
    end

    def managed_project_folder_path
      managed_folder_identifier.path
    end

    def managed_project_folder_name
      managed_folder_identifier.name
    end

    def project_folder_location
      managed_folder_identifier.location
    end

    def project_folder_path_escaped
      UrlBuilder.path(managed_project_folder_path)
    end

    def file_inside_project_folder?(escaped_file_path)
      escaped_file_path.match?(%r|^/#{project_folder_path_escaped}|)
    end

    def open(user)
      auth_strategy = Adapters::Registry.resolve("#{storage}.authentication.user_bound").call(user, storage)

      result = if project_folder_not_accessible?(user)
                 Adapters::Registry.resolve("#{storage}.queries.open_storage").call(storage:, auth_strategy:, input_data: nil)
               else
                 open_file_link(auth_strategy)
               end

      # FIXME: We probably could make this into a service by itself.
      #   so errors can be more descriptive. 2025-05-05 @mereghost
      result.either(-> { ServiceResult.success(result: it) }, -> { ServiceResult.failure(errors: it) })
    end

    def open_project_storage_url
      OpenProject::StaticRouting::StaticRouter.new.url_helpers.open_project_storage_url(project_id: project.identifier, id:)
    end

    private

    def open_file_link(auth_strategy)
      Adapters::Input::OpenFileLink.build(file_id: project_folder_id).bind do |input_data|
        Adapters::Registry.resolve("#{storage}.queries.open_file_link").call(storage:, auth_strategy:, input_data:)
      end
    end

    def managed_folder_identifier
      @managed_folder_identifier ||= Adapters::Registry.resolve("#{storage}.models.managed_folder_identifier").new(self)
    end

    def project_folder_not_accessible?(user)
      project_folder_inactive? ||
        (project_folder_automatic? && !user.allowed_in_project?(:read_files, project)) ||
        project_folder_id.blank?
    end
  end
end
