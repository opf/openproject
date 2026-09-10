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

module Admin
  module TextTransformActions
    # Prototype only: lets an administrator run the action against arbitrary text
    # through the execute API and watch the run being polled.
    class SandboxComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include API::V3::Utilities::PathHelper

      DIALOG_ID = "ai-text-transform-sandbox-details"

      alias action model

      private

      def controller_data
        {
          controller: "ai-text-transform-sandbox",
          ai_text_transform_sandbox_url_value: api_v3_paths.ai_text_transform_runs,
          ai_text_transform_sandbox_action_id_value: action.id
        }
      end

      def form_data
        {
          controller: "show-when-value-selected",
          action: "submit->ai-text-transform-sandbox#submit"
        }
      end

      def target(name)
        { ai_text_transform_sandbox_target: name }
      end

      def label(key)
        I18n.t("admin.text_transform_actions.sandbox.#{key}")
      end

      def types
        Type.order(:position)
      end
    end
  end
end
