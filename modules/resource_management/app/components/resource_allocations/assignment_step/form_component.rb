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
  module AssignmentStep
    # The candidate-selection step: project members matching the allocation's
    # filter, each flagged for fit, picked by radio button.
    class FormComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def initialize(project:, allocation:, candidates:, error: nil)
        super

        @project = project
        @allocation = allocation
        @candidates = candidates
        @error = error
      end

      def wrapper_key
        ResourceAllocations::AssignmentDialogComponent::BODY_ID
      end

      private

      attr_reader :project, :allocation, :candidates, :error

      def filter_summary
        @filter_summary ||= Queries::FilterSummary.new(allocation.user_filter)
      end

      # The allocation's work package, only when the current user may see it.
      def work_package
        entity = allocation.entity
        return unless entity.is_a?(WorkPackage) && WorkPackage.visible(User.current).exists?(id: entity.id)

        entity
      end

      def period_label
        "#{format_date_or_dash(allocation.start_date)} – #{format_date_or_dash(allocation.end_date)}"
      end

      def requested_value
        DurationConverter.output(allocation.allocated_hours)
      end

      def format_date_or_dash(date)
        date.present? ? helpers.format_date(date) : "—"
      end

      def detail_label(text)
        render(Primer::Beta::Text.new(tag: :div, font_size: :small, font_weight: :bold)) { text }
      end

      def detail_block(label, value)
        render(Primer::Box.new(mb: 3)) do
          safe_join(
            [
              detail_label(label),
              render(Primer::Beta::Text.new(tag: :div, font_size: :small)) { value }
            ]
          )
        end
      end

      def form_url
        helpers.project_staffing_assign_path(project, allocation)
      end

      def form_id
        ResourceAllocations::AssignmentDialogComponent::FORM_ID
      end
    end
  end
end
