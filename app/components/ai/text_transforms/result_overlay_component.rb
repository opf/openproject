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
    # Demo only (AI-126): the AI result pane. Wraps Primer::Alpha::Overlay without changing it;
    # its Stimulus controller runs the chosen action through the run API (AI-136) and owns the
    # feature-specific dragging and resizing.
    class ResultOverlayComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include API::V3::Utilities::PathHelper
      include ResultPaneHelpers

      OVERLAY_ID = "ai-text-transform-result"
      ANCHOR_ID = "ai-text-transform-result-anchor"

      def self.visible_for?(user)
        user.logged? &&
          OpenProject::FeatureDecisions.ai_text_transform_actions_active? &&
          Setting.ai_text_transform_actions_enabled?
      end

      private

      def variant = "overlay"

      def css_prefix = "op-ai-result-overlay"

      def section(name)
        render(ResultPaneSectionComponent.new(section: name, css_prefix:))
      end

      def controller_data
        {
          controller: "ai-text-transform-result-overlay",
          ai_text_transform_result_overlay_variant_value: variant,
          ai_text_transform_result_overlay_runs_url_value: api_v3_paths.ai_text_transform_runs,
          ai_text_transform_result_overlay_render_url_value: helpers.ai_text_transform_preview_path,
          ai_text_transform_result_overlay_editor_gone_value: label(:editor_gone),
          ai_text_transform_result_overlay_selection_gone_value: label(:selection_gone),
          ai_text_transform_result_overlay_context_document_value: label(:context_description),
          ai_text_transform_result_overlay_context_selection_value: label(:context_selection),
          ai_text_transform_result_overlay_copied_value: label(:copied),
          ai_text_transform_result_overlay_copy_value: label(:copy)
        }
      end
    end
  end
end
