# frozen_string_literal: true

# -- copyright
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
# ++

module Projects
  # rubocop:disable OpenProject/AddPreviewForViewComponent
  class IndexSubHeaderComponent < ApplicationComponent
    # rubocop:enable OpenProject/AddPreviewForViewComponent
    include ApplicationHelper
    include OpTurbo::Streamable

    def initialize(query:, current_user:, disable_buttons: nil)
      super
      @query = query
      @current_user = current_user
      @disable_buttons = disable_buttons
    end

    def self.wrapper_key
      "projects-index-sub-header"
    end

    def filter_input_value
      @query.find_active_filter(:name_and_identifier)&.values&.first
    end

    def sub_header_data_attributes
      {
        controller: "filter--filters-form",
        "filter--filters-form-perform-turbo-requests-value": true,
        "filter--filters-form-clear-button-id-value": clear_button_id,
        "filter--filters-form-display-filters-value": filters_expanded?
      }
    end

    def filter_input_data_attributes
      {
        "filter-name": "name_and_identifier",
        "filter-type": "string",
        "filter-operator": "~",
        "filter--filters-form-target": "simpleFilter filterValueContainer simpleValue"
      }
    end

    def clear_button_id
      "project-filters-form-clear-button"
    end

    def new_workspace_path(type)
      return unless Project.workspace_types.key?(type)

      url_for([:new, type.to_sym])
    end

    def new_workspace_label(type)
      I18n.t(:"label_#{type}")
    end

    def allowed_new_workspace_types
      @allowed_new_workspace_types ||= [].tap do |types|
        types << "portfolio" if @current_user.allowed_globally?(:add_portfolios)
        types << "program" if @current_user.allowed_globally?(:add_programs)
        types << "project" if @current_user.allowed_globally?(:add_project)
      end
    end

    def for_a_single_new_allowed_type
      return unless allowed_new_workspace_types.length == 1

      yield allowed_new_workspace_types[0]
    end

    def for_multiple_new_allowed_types
      return unless allowed_new_workspace_types.length > 1

      yield allowed_new_workspace_types
    end

    def workspace_type_enterprise_feature_allowed?(workspace_type)
      return EnterpriseToken.allows_to?(:portfolio_management) if workspace_type.in?(%w[portfolio program])

      true
    end

    def filters_expanded?
      params[:filters].present?
    end
  end
end
