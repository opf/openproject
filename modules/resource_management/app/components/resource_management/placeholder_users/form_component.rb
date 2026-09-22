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

module ResourceManagement
  module PlaceholderUsers
    class FormComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def initialize(placeholder_user:)
        super

        @placeholder_user = placeholder_user
      end

      def wrapper_key
        NewDialogComponent::BODY_ID
      end

      private

      def form_url
        resource_management_placeholder_users_path
      end

      # The criteria are built by a filter form rather than a model-bound field,
      # so their errors have nowhere to render inline.
      def criteria_errors
        @placeholder_user.errors.full_messages_for(:user_filter)
      end

      # Only project members can be allocated, so the project scoping is applied
      # when the criteria are read rather than offered as a filter here.
      def criteria_form(form)
        ::Filters::FilterFormComponent.new(
          builder: form,
          query: @placeholder_user.candidate_query,
          excluded_filters: [:member],
          hidden_input_name: "filters",
          output_format: :json,
          autocomplete_append_to: "##{NewDialogComponent::DIALOG_ID}"
        )
      end

      # The filter controller sits on the form so that submitting it serializes
      # the criteria into the hidden field first; on its own it only syncs them
      # after a debounce.
      def form_data
        {
          turbo_stream: true,
          controller: "filter--filters-form",
          action: "submit->filter--filters-form#sendForm",
          filter__filters_form_output_format_value: "json"
        }
      end
    end
  end
end
