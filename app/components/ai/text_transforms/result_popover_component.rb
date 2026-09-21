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
    # Demo only (AI-126): the AI result popover. Rendered once per page and driven by
    # its Stimulus controller, which runs the chosen action through the run API (AI-136).
    class ResultPopoverComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include API::V3::Utilities::PathHelper

      def self.visible_for?(user)
        user.logged? &&
          OpenProject::FeatureDecisions.ai_text_transform_actions_active? &&
          Setting.ai_text_transform_actions_enabled?
      end

      private

      def controller_data
        {
          controller: "ai-text-transform-popover",
          ai_text_transform_popover_runs_url_value: api_v3_paths.ai_text_transform_runs,
          ai_text_transform_popover_render_url_value: api_v3_paths.render_markup,
          ai_text_transform_popover_work_package_link_value: api_v3_paths.work_package("__id__"),
          ai_text_transform_popover_editor_gone_value: label(:editor_gone),
          ai_text_transform_popover_copied_value: label(:copied),
          ai_text_transform_popover_copy_value: label(:copy)
        }
      end

      def target(name)
        { ai_text_transform_popover_target: name }
      end

      def action(name)
        { action: "click->ai-text-transform-popover##{name}" }
      end

      def label(key)
        I18n.t("ai.text_transform.popover.#{key}")
      end
    end
  end
end
