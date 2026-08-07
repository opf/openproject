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
    # Picks the resource an allocation asks for from the existing catalogue.
    # Its criteria are shown read-only underneath, so an allocation never
    # describes a resource inline.
    class UserResourceForm < ApplicationForm
      form do |f|
        f.autocompleter(
          name: :user_resource_id,
          label: ResourceAllocation.human_attribute_name(:user_resource),
          required: true,
          autocomplete_options: {
            component: "opce-autocompleter",
            url: ::API::V3::Utilities::PathHelper::ApiV3Path.user_resources,
            resource: "user_resources",
            searchKey: "any_name_attribute",
            bindLabel: "name",
            multiple: false,
            focusDirectly: false,
            appendTo: "##{@dialog_id}",
            # Refreshes the criteria shown below for the picked resource.
            data: { action: "change->refresh-on-form-changes#triggerTurboStream" }
          }
        ) do |list|
          # The current selection is rendered server-side so the autocompleter
          # does not have to resolve it before the form is usable.
          if model.user_resource
            list.option(value: model.user_resource.id, label: model.user_resource.name, selected: true)
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
