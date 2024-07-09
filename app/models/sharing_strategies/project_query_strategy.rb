#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module SharingStrategies
  class ProjectQueryStrategy < BaseStrategy
    def available_roles
      role_mapping = ProjectQueryRole.pluck(:builtin, :id).to_h

      [
        {
          label: I18n.t("sharing.project_queries.permissions.edit"),
          value: role_mapping[Role::BUILTIN_PROJECT_QUERY_EDIT],
          description: I18n.t("sharing.project_queries.permissions.edit_description")
        },
        {
          label: I18n.t("sharing.project_queries.permissions.view"),
          value: role_mapping[Role::BUILTIN_PROJECT_QUERY_VIEW],
          description: I18n.t("sharing.project_queries.permissions.view_description"),
          default: true
        }
      ]
    end

    def manageable?
      @entity.editable?
    end

    def viewable?
      @entity.visible?
    end

    def create_contract_class
      Shares::ProjectQueries::CreateContract
    end

    def update_contract_class
      Shares::ProjectQueries::UpdateContract
    end

    def delete_contract_class
      Shares::ProjectQueries::DeleteContract
    end

    def additional_body_components
      [
        Shares::ProjectQueries::PublicFlagComponent,
        Shares::ProjectQueries::ProjectAccessWarningComponent
      ]
    end

    def empty_state_component
      Shares::ProjectQueries::EmptyStateComponent
    end

    def shares(reload: false)
      results = super

      if results.present?
        (results + [virtual_owner_share]).sort_by { |share| share.principal.name }
      else
        []
      end
    end

    private

    def virtual_owner_share
      @virtual_owner_share ||= Member.new(
        entity:,
        principal: entity.user,
        roles: [ProjectQueryRole.find_by(builtin: owner_role_identifier)]
      )
    end

    def owner_role_identifier
      if entity.editable?(entity.user)
        Role::BUILTIN_PROJECT_QUERY_EDIT
      else
        Role::BUILTIN_PROJECT_QUERY_VIEW
      end
    end
  end
end
