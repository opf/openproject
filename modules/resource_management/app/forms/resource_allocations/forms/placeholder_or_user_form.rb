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

module ResourceAllocations
  module Forms
    class PlaceholderOrUserForm < ApplicationForm
      form do |f|
        f.autocompleter(
          name: :placeholder_or_user_id,
          label: ResourceAllocation.human_attribute_name(:placeholder_or_user),
          required: true,
          invalid: principal_error.present?,
          validation_message: principal_error,
          autocomplete_options: {
            component: "opce-resource-allocation-autocompleter",
            # The endpoint answers who may be allocated against, so the criteria
            # and permission rules are not repeated here.
            url: ::API::V3::Utilities::PathHelper::ApiV3Path.allocatable_principals,
            resource: "principals",
            searchKey: "any_name_attribute",
            filters: principal_filters,
            defaultData: true,
            focusDirectly: false,
            multiple: false,
            appendTo: "##{@dialog_id}",
            data: { action: "change->refresh-on-form-changes#triggerTurboStream" }
          }
        )

        f.html_content do
          render(ResourceAllocations::AllocationStep::ResourceFilterComponent.new(allocation: model))
        end
      end

      def initialize(project:, dialog_id:, view: nil)
        super()
        @project = project
        @dialog_id = dialog_id
        @view = view
      end

      private

      # The field is `placeholder_or_user_id` but the model keys errors on the
      # `principal` association; relabel them onto this field.
      def principal_error
        label = ResourceAllocation.human_attribute_name(:placeholder_or_user)
        model.errors.messages_for(:principal)
             .map { |message| "#{label} #{message}" }
             .join(" ")
             .presence
      end

      # Constrains the picker to the project's users — placeholder users are not
      # bound to a project and pass this filter — and additionally to the planner
      # view's users when the dialog was opened from a user view.
      def principal_filters
        filters = [
          { name: "allocatable_in_project", operator: "=", values: [@project.id.to_s] }
        ]
        filters.concat(@view.allocation_principal_filters) if @view&.allocation_principal_filters
        filters
      end
    end
  end
end
