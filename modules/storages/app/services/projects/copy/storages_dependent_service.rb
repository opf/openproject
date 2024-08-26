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

module Projects::Copy
  class StoragesDependentService < Dependency
    using Storages::Peripherals::ServiceResultRefinements

    def self.human_name
      I18n.t(:label_project_storage_plural)
    end

    def source_count
      source.storages.count
    end

    protected

    # rubocop:disable Metrics/AbcSize
    def copy_dependency(*)
      state.copied_project_storages = source.project_storages.each_with_object([]) do |source_project_storage, array|
        project_storage_copy =
          ::Storages::ProjectStorages::CreateService
            .new(user: User.current, contract_class: ::Storages::ProjectStorages::CopyContract)
            .call(storage_id: source_project_storage.storage_id,
                  project_id: target.id,
                  project_folder_mode: "inactive")
            .on_failure { |r| add_error!(source_project_storage.class.to_s, r.to_active_model_errors) }
            .result

        array << { source: source_project_storage, target: project_storage_copy }
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
