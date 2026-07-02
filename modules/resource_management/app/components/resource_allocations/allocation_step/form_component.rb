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
  module AllocationStep
    class FormComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      # `dialog_id` names the dialog hosting the form (autocompleter dropdowns
      # attach to it): the create wizard's by default, the edit dialog's when
      # editing a persisted allocation.
      def initialize(allocation:, project:, allocation_kind:,
                     dialog_id: ResourceAllocations::NewDialogComponent::DIALOG_ID,
                     resource_planner_id: nil)
        super
        @allocation = allocation
        @project = project
        @allocation_kind = allocation_kind
        @dialog_id = dialog_id
        @resource_planner_id = resource_planner_id
      end

      def wrapper_key
        ResourceAllocations::NewDialogComponent::BODY_ID
      end

      private

      attr_reader :dialog_id

      def filter_based?
        @allocation_kind.to_s == "filter"
      end

      # A persisted allocation submits an update to itself; a new one goes
      # through the create flow (with its confirmation step).
      def form_url
        if @allocation.persisted?
          project_resource_allocation_path(@project, @allocation, resource_planner_id: @resource_planner_id)
        else
          project_resource_allocations_path(@project, resource_planner_id: @resource_planner_id)
        end
      end

      def form_method
        @allocation.persisted? ? :patch : :post
      end

      def form_list_component(form)
        prepends = if filter_based?
                     [
                       ResourceAllocations::Forms::FilterNameForm.new(form),
                       ::Filters::FilterFormComponent.new(
                         builder: form,
                         query: @allocation.candidate_query,
                         wrap_with_controller: true,
                         hidden_input_name: "filters",
                         output_format: :json,
                         autocomplete_append_to: "##{dialog_id}"
                       )
                     ]
                   else
                     [
                       ResourceAllocations::Forms::PrincipalForm.new(
                         form,
                         project: @project,
                         dialog_id: dialog_id
                       )
                     ]
                   end

        Primer::Forms::FormList.new(
          *prepends,
          ResourceAllocations::Forms::WorkPackageForm.new(form, project: @project, dialog_id: dialog_id),
          ResourceAllocations::Forms::DateRangeForm.new(form, dialog_id: dialog_id),
          ResourceAllocations::Forms::HoursForm.new(form),
          ResourceAllocations::Forms::AllocationKindForm.new(form, allocation_kind: @allocation_kind)
        )
      end
    end
  end
end
