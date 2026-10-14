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
  module AssistantChats
    # Runs the built-in checks for the first answer of a skill that has them, and stores the
    # rule findings on that answer at once, so the dialog shows them while the AI answers.
    class RunChecks
      attr_reader :message

      def initialize(message)
        @message = message
      end

      def call
        skill = message.chat.skill
        context = skill.skill_type.build_context(work_package: message.chat.work_package, user: message.chat.user)
        findings = skill.rules.flat_map { |rule| rule.call(context) }
        findings.each_with_index do |finding, index|
          message.proposals.create!(finding.merge(position: index, base_lock_version: message.base_lock_version))
        end
        message.update!(not_checked: context.not_checked)
        message.log_event(:rules, findings: findings.size, review: skill.ai_review_blocker ? "skipped" : "started")
      end
    end
  end
end
