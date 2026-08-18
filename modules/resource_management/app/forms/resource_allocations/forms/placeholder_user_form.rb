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
# See COPYRIGHT and LICENSE files for more details.
#++

module ResourceAllocations
  module Forms
    class PlaceholderUserForm < ApplicationForm
      form do |f|
        f.autocompleter(
          name: :placeholder_user_id,
          label: ResourceAllocation.human_attribute_name(:placeholder_user),
          required: true,
          autocomplete_options: {
            component: "opce-user-autocompleter",
            url: ::API::V3::Utilities::PathHelper::ApiV3Path.placeholder_users,
            resource: "principals",
            searchKey: "any_name_attribute",
            filters: [{ name: "has_user_filter", operator: "=", values: ["with_criteria"] }],
            multiple: false,
            focusDirectly: false,
            appendTo: "##{@dialog_id}",
            data: { action: "change->refresh-on-form-changes#triggerTurboStream" }
          }
        ) do |list|
          if model.placeholder_user
            list.option(value: model.placeholder_user.id, label: model.placeholder_user.name, selected: true)
          end
        end

        f.html_content do
          render(ResourceAllocations::AllocationStep::ResourceFilterComponent.new(allocation: model))
        end
      end

      def initialize(dialog_id:)
        super()
        @dialog_id = dialog_id
      end
    end
  end
end
