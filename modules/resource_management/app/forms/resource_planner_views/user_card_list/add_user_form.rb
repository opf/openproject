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

module ResourcePlannerViews
  module UserCardList
    class AddUserForm < ApplicationForm
      form do |f|
        f.autocompleter(
          name: :user_id,
          label: User.model_name.human,
          required: true,
          autocomplete_options: {
            component: "opce-user-autocompleter",
            url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals,
            resource: "principals",
            searchKey: "any_name_attribute",
            focusDirectly: true,
            multiple: false,
            appendTo: "##{@append_to}",
            filters: autocomplete_filters
          }
        )
      end

      def initialize(project:, append_to:, excluded_ids: [])
        super()
        @project = project
        @append_to = append_to
        @excluded_ids = excluded_ids
      end

      private

      def autocomplete_filters
        filters = [
          { name: "type", operator: "=", values: %w[User] },
          { name: "member", operator: "=", values: [@project.id.to_s] }
        ]

        if @excluded_ids.present?
          filters << { name: "id", operator: "!", values: @excluded_ids.map(&:to_s) }
        end

        filters
      end
    end
  end
end
