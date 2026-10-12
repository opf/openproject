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
  module AssistantRuns
    # Starts a run of a skill on a work package for a user, and executes it at once.
    # The trigger records why the run started: the menu now, an automation later. The run
    # and its findings are stored for that user only.
    class RunService
      # A judgement job that did not finish in this time is treated as lost.
      AI_RUN_TIMEOUT = 10.minutes

      attr_reader :skill, :work_package, :user, :trigger, :automation

      def initialize(skill:, work_package:, user:, trigger: "menu", automation: nil)
        @skill = skill
        @work_package = work_package
        @user = user
        @trigger = trigger.to_s
        @automation = automation
      end

      def call
        unless AI::AssistantSkills::Registry.fetch(skill.skill_key)
          return ServiceResult.failure(message: I18n.t("ai_assistance.errors.unknown_skill"))
        end

        running = running_judgement
        return ServiceResult.success(result: running) if running

        run = create_run
        Execution.new(run).call
        ServiceResult.success(result: run)
      end

      private

      # Only one judgement runs at a time for a user, a work package and a skill. Another
      # start opens the run that is in progress instead of paying for a second one.
      def running_judgement
        runs = AI::AssistantRun.for(user, work_package).where(skill:).ai_running
        runs.where(created_at: ...AI_RUN_TIMEOUT.ago).find_each do |lost|
          lost.add_not_checked(:ai_judgement, :timed_out)
          lost.update!(status: "finished")
        end
        runs.where(created_at: AI_RUN_TIMEOUT.ago..).newest_first.first
      end

      def create_run
        AI::AssistantRun.create!(skill:, work_package:, user:, trigger:, automation:,
                                 work_package_lock_version: work_package.lock_version,
                                 locale: locale.to_s)
      end

      def locale
        @locale ||= user.language.presence&.to_sym.then { |l| I18n.available_locales.include?(l) ? l : I18n.default_locale }
      end
    end
  end
end
