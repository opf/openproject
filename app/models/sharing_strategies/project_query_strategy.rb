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
      return results if filter_for_groups?

      if (!filtered_by_role? && results.present?) || owner_matches_role_filter?
        (results + [virtual_owner_share]).sort_by { |share| share.principal.name }
      else
        results
      end
    end

    def share_description(share) # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
      return I18n.t("sharing.user_details.invited") if !manageable? && share.principal.invited?
      return "" if !manageable?

      scope = %i[sharing project_queries user_details]

      if share.principal == entity.user
        I18n.t(:owner, scope:)
      elsif entity.public?
        if share.principal.is_a?(User) && share.principal.allowed_globally?(:manage_public_project_queries)
          I18n.t(:can_manage_public_lists, scope:)
        elsif share.roles.any? { |role| role.builtin == Role::BUILTIN_PROJECT_QUERY_VIEW }
          I18n.t(:can_view_because_public, scope:)
        end
      end
    end

    def manage_shares_component(modal_content:, errors:)
      if EnterpriseToken.allows_to?(:project_list_sharing)
        super
      else
        Shares::ProjectQueries::UpsaleComponent.new(modal_content:)
      end
    end

    def title
      I18n.t(:label_share_project_list)
    end

    private

    def virtual_owner_share
      @virtual_owner_share ||= Member.new(
        entity:,
        principal: entity.user,
        roles: [owner_role]
      )
    end

    def owner_role
      @owner_role ||= if entity.editable?(entity.user)
                        ProjectQueryRole.find_by(builtin: Role::BUILTIN_PROJECT_QUERY_EDIT)
                      else
                        ProjectQueryRole.find_by(builtin: Role::BUILTIN_PROJECT_QUERY_VIEW)
                      end
    end

    def filtered_by_role?
      role_filter.present?
    end

    def role_filter
      @role_filter ||= query.filters.find { |filter| filter.is_a?(Queries::Members::Filters::RoleFilter) }
    end

    def owner_matches_role_filter?
      return false unless filtered_by_role?

      role_filter.values.include?(owner_role.id.to_s) # rubocop:disable Performance/InefficientHashSearch
    end

    def filter_for_groups?
      principal_filter = query.filters.find { |filter| filter.is_a?(Queries::Members::Filters::PrincipalTypeFilter) }
      return false if principal_filter.nil?

      principal_filter.values.count == 1 && principal_filter.values.include?("Group") # rubocop:disable Performance/InefficientHashSearch
    end
  end
end
