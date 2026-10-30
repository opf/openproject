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

module WorkPackageTypes
  module ProjectsTab
    module Links
      class CandidatesController < BaseTabController
        def index
          render TreeComponent.new(variant: @variant,
                                   nodes: ::Project.build_projects_hierarchy(candidate_projects),
                                   builder: ActionView::Helpers::FormBuilder.new("", nil, view_context, {}),
                                   form_name: params[:name]),
                 layout: false
        end

        private

        def candidate_projects
          scope = ::Project.order(:lft)
          return scope.to_a if filter_term.blank?

          matching = Queries::Projects::Filters::NameAndIdentifierFilter
                       .create!(operator: "~", values: [sanitized_filter_term])
                       .apply_to(scope)
          scope.self_and_ancestors_of(matching).to_a
        end

        def filter_term = params[:query].to_s.strip

        def sanitized_filter_term = ActiveRecord::Base.sanitize_sql_like(filter_term)
      end
    end
  end
end
