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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module AI
  module TextTransforms
    module ResultPaneHelpers
      STIMULUS_CONTROLLER = "ai-text-transform-pane"
      CLOSE_FORM_ID = "ai-text-transform-pane-close"
      APPLY_FORM_ID = "ai-text-transform-pane-apply"
      RETRY_FORM_ID = "ai-text-transform-pane-retry"

      private

      def label(key)
        I18n.t("ai.text_transform.pane.#{key}")
      end

      def target(name)
        { ai_text_transform_pane_target: name }
      end

      def action(**events_by_name)
        { action: events_by_name.map { |name, event| "#{event}->#{STIMULUS_CONTROLLER}##{name}" }.join(" ") }
      end
    end
  end
end
