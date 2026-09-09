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
    class CreateRun
      def initialize(user:, action:, context:, content:, availability: Availability.new)
        @user = user
        @action = action
        @context = context
        @content = content
        @availability = availability
      end

      def call
        run = build_run
        return unavailable(run) unless action && availability.action(action, context).available?
        return ServiceResult.failure(result: run, errors: run.errors) unless run.save

        AI::TextTransformJob.perform_later(run.id)
        ServiceResult.success(result: run)
      end

      private

      attr_reader :user, :action, :context, :content, :availability

      def unavailable(run)
        run.errors.add(:base,
                       :not_available,
                       message: I18n.t("api_v3.errors.ai_text_transform.action_not_available"),
                       reason: unavailable_reason)
        ServiceResult.failure(result: run, errors: run.errors)
      end

      def unavailable_reason
        action ? availability.action(action, context).reason : :unknown_action
      end

      def build_run
        AI::TextTransformRun.new(user:, action:, input: content, system_prompt:)
      end

      def system_prompt
        return "" if action.nil?

        Prompt.build(action:, context:, content:).system
      end
    end
  end
end
