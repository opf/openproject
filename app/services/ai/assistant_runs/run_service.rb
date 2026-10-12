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
    # Starts a run of a skill on a work package for a user. The rules run at once,
    # in the user's locale; the run and its findings are stored for that user only.
    class RunService
      attr_reader :skill, :work_package, :user

      def initialize(skill:, work_package:, user:)
        @skill = skill
        @work_package = work_package
        @user = user
      end

      def call
        skill_type = AI::AssistantSkills::Registry.fetch(skill.skill_key)
        return ServiceResult.failure(message: I18n.t("ai_assistance.errors.unknown_skill")) unless skill_type

        run = AI::AssistantRun.transaction { create_run(skill_type) }
        ServiceResult.success(result: run)
      end

      private

      def create_run(skill_type)
        run = AI::AssistantRun.create!(skill:, work_package:, user:,
                                       work_package_lock_version: work_package.lock_version,
                                       locale: locale.to_s)

        I18n.with_locale(locale) do
          context = skill_type.build_context(work_package:, user:)
          skill_type.rules.flat_map { |rule| rule.call(context) }.each do |finding|
            run.findings.create!(finding.to_record_attributes.merge(base_lock_version: run.work_package_lock_version))
          end
          run.not_checked = context.not_checked
        end

        run.update!(status: "finished")
        run
      end

      def locale
        @locale ||= user.language.presence&.to_sym.then { |l| I18n.available_locales.include?(l) ? l : I18n.default_locale }
      end
    end
  end
end
