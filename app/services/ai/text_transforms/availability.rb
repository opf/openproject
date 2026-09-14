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
    class Availability
      REASONS = %i[
        feature_disabled
        assistant_disabled
        llm_unavailable
        action_inactive
        context_required
        type_mismatch
        template_missing
      ].freeze

      Result = Data.define(:available, :reason) do
        def available? = available
      end

      def initialize(gateway: Gateway.build)
        @gateway = gateway
      end

      def assistant
        @assistant ||= check_assistant
      end

      def action(action, context)
        return assistant unless assistant.available?

        action_matches(action, context)
      end

      def runnable(action)
        return assistant unless assistant.available?
        return Result.new(false, :action_inactive) unless action.active?

        Result.new(true, nil)
      end

      def actions_for(context)
        return [] unless assistant.available?

        AI::TextTransformAction
          .active
          .ordered
          .includes(:types)
          .select { |candidate| action_matches(candidate, context).available? }
      end

      private

      attr_reader :gateway

      def check_assistant
        if !OpenProject::FeatureDecisions.ai_text_transform_actions_active?
          Result.new(false, :feature_disabled)
        elsif !Setting.ai_text_transform_actions_enabled?
          Result.new(false, :assistant_disabled)
        elsif !gateway.readiness.ready?
          Result.new(false, :llm_unavailable)
        else
          Result.new(true, nil)
        end
      end

      def action_matches(action, context)
        reason = mismatch_reason(action, context)
        reason ? Result.new(false, reason) : Result.new(true, nil)
      end

      def mismatch_reason(action, context)
        return :action_inactive unless action.active?
        return :template_missing if action.injects_type_template? && context.template.blank?

        scope_reason(action, context)
      end

      def scope_reason(action, context)
        return if action.everywhere?
        return :context_required if context.type.nil?
        return :type_mismatch if action.specific_work_package_types? && action.types.exclude?(context.type)

        nil
      end
    end
  end
end
