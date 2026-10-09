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

module AI
  module TextTransforms
    # Demo only (AI-126): the AI result pane, a Primer::Beta::BorderBox composition the server
    # renders on demand and updates section by section while the run streams in. Dragging and
    # resizing are feature code in its Stimulus controller.
    class ResultPaneComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers
      include ResultPaneHelpers

      EDGES = %w[left right bottom-left bottom-right].freeze

      def initialize(pane:)
        super()
        @pane = pane
      end

      private

      attr_reader :pane

      def section(name)
        render(ResultPaneSectionComponent.new(section: name, pane:))
      end

      def wrapper_data
        {
          controller: "ai-text-transform-pane",
          ai_text_transform_pane_close_form_value: CLOSE_FORM_ID,
          ai_text_transform_pane_editor_gone_value: label(:editor_gone),
          ai_text_transform_pane_selection_gone_value: label(:selection_gone),
          ai_text_transform_pane_copied_value: label(:copied),
          ai_text_transform_pane_copy_value: label(:copy),
          test_selector: "ai-text-transform-result"
        }
      end
    end
  end
end
