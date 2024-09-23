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
  class BaseStrategy
    attr_reader :entity, :user

    def initialize(entity, query_params:, user: User.current)
      @entity = entity
      @user = user
      @query_params = query_params
    end

    def available_roles
      # format: [{ label: "Role name", value: 42, description: "Role description", default: true }]
      raise NotImplementedError, "Override in a subclass and return an array of roles that should be displayed"
    end

    def viewable?
      raise NotImplementedError,
            "Override in a subclass and return true if the current user can view who the entity is shared with"
    end

    def manageable?
      raise NotImplementedError, "Override in a subclass and return true if the current user can manage sharing"
    end

    def create_contract_class
      raise NotImplementedError, "Override in a subclass and return the contract class for creating a share"
    end

    def update_contract_class
      raise NotImplementedError, "Override in a subclass and return the contract class for updating a share"
    end

    def delete_contract_class
      raise NotImplementedError, "Override in a subclass and return the contract class for deleting a share"
    end

    def share_description(share)
      raise NotImplementedError, "Override in a subclass and return a description for the shared user"
    end

    def title
      raise NotImplementedError, "Override in a subclass and return a title for the sharing dialog"
    end

    def custom_body_components?
      !additional_body_components.empty?
    end

    # Override by returning a list of component classes that should be rendered in the sharing dialog above the table of shares
    def additional_body_components
      []
    end

    def custom_empty_state_component?
      empty_state_component.present?
    end

    # Override by returning a component class that should be rendered in the sharing dialog instead of the table of shares
    # when there is no share yet
    def empty_state_component
      nil
    end

    def modal_body_component(errors)
      Shares::ModalBodyComponent.new(strategy: self, errors:)
    end

    def manage_shares_component(modal_content:, errors:)
      Shares::ManageSharesComponent.new(strategy: self, modal_content:, errors:)
    end

    def query # rubocop:disable Metrics/AbcSize
      return @query if defined?(@query)

      @query = ParamsToQueryService
                 .new(Member, user, query_class: Queries::Members::NonInheritedMemberQuery)
                 .call(@query_params)

      # Set default filter on the entity
      @query.where("entity_id", "=", entity.id)
      @query.where("entity_type", "=", entity.class.name)
      if entity.respond_to?(:project)
        @query.where("project_id", "=", entity.project.id)
      end

      @query.order(name: :asc) unless @query_params[:sortBy]

      @query
    end

    def shares(reload: false)
      @shares = nil if reload
      @shares ||= query.results
    end
  end
end
