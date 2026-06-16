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
    class PrincipalForm < ApplicationForm
      form do |f|
        f.autocompleter(
          name: :principal_id,
          label: ResourceAllocation.human_attribute_name(:principal),
          required: true,
          invalid: principal_error.present?,
          validation_message: principal_error,
          autocomplete_options: {
            component: "opce-user-autocompleter",
            url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals,
            resource: "principals",
            searchKey: "any_name_attribute",
            filters: principal_filters,
            defaultData: true,
            focusDirectly: false,
            multiple: false,
            appendTo: "##{@dialog_id}"
          }
        )
      end

      def initialize(project:, dialog_id:)
        super()
        @project = project
        @dialog_id = dialog_id
      end

      private

      # The field is `principal_id` but the model keys errors on the `principal`
      # association; relabel them onto this field.
      def principal_error
        label = ResourceAllocation.human_attribute_name(:principal)
        model.errors.messages_for(:principal)
             .map { |message| "#{label} #{message}" }
             .join(" ")
             .presence
      end

      def principal_filters
        [
          { name: "type", operator: "=", values: %w[User] },
          { name: "status", operator: "=", values: [Principal.statuses[:active]] },
          { name: "member", operator: "=", values: [@project.id.to_s] }
        ]
      end
    end
  end
end
