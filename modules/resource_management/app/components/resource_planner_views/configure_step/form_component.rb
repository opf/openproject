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
  module ConfigureStep
    # Shared by the new-view and edit dialogs. `form_id` lets the surrounding
    # dialog wire its submit button to this form via `<button form="...">`, and
    # `wrapper_key` is overridable so it can be slotted into either dialog's
    # (separately replaceable) body.
    class FormComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def initialize(view:,
                     url:,
                     method: :post,
                     hidden_fields: {},
                     form_id: ResourcePlannerViews::NewDialogComponent::FORM_ID,
                     dialog_id: ResourcePlannerViews::NewDialogComponent::DIALOG_ID,
                     wrapper_key: "resource_planner_view_step_body",
                     filter_query: nil)
        super
        @view = view
        @url = url
        @method = method
        @hidden_fields = hidden_fields
        @form_id = form_id
        @dialog_id = dialog_id
        @wrapper_key = wrapper_key
        @filter_query = filter_query
      end

      attr_reader :wrapper_key

      private

      # Matches the initially-checked radio on first render; the
      # show-when-value-selected controller takes over after that.
      def initial_filter_mode_automatic?
        !(@view.respond_to?(:manually_picked?) && @view.manually_picked?)
      end

      def has_filter_query?
        @filter_query.present?
      end
    end
  end
end
