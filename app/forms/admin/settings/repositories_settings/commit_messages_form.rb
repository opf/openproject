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

module Admin
  module Settings
    module RepositoriesSettings
      class CommitMessagesForm < ApplicationForm
        class CommitLogTimeForm < ApplicationForm
          settings_form do |sf|
            sf.select_list(
              name: :commit_logtime_activity_id,
              values: available_activities,
              disabled: !Setting.commit_logtime_enabled?,
              input_width: :medium,
              include_blank: I18n.t(:label_default),
              data: {
                disable_when_checked_target: "effect",
                target_name: "commit_logtime_activity_id"
              }
            )
          end

          def available_activities
            TimeEntryActivity.shared.pluck(:name, :id)
          end
        end

        settings_form do |sf|
          sf.text_field(
            name: :commit_ref_keywords,
            caption: I18n.t(:text_comma_separated)
          )

          sf.group(layout: :horizontal) do |group|
            group.text_field(
              name: :commit_fix_keywords,
              label: I18n.t(%i[setting_commit_fix_keywords label_keyword_plural]).join(": "),
              caption: I18n.t(:text_comma_separated)
            )

            group.select_list(
              name: :commit_fix_status_id,
              values: available_statuses,
              label: I18n.t(%i[setting_commit_fix_keywords label_applied_status]).join(": "),
              prompt: "--- #{I18n.t(:actionview_instancetag_blank_option)} ---"
            )
          end

          sf.check_box(
            name: :commit_logtime_enabled,
            data: {
              show_when_checked_target: "cause",
              disable_when_checked_target: "cause",
              target_name: "commit_logtime_activity_id"
            }
          ) do |commit_logtime_check_box|
            commit_logtime_check_box.nested_form(
              classes: ["mt-2", { "d-none" => !Setting.commit_logtime_enabled? }],
              data: {
                show_when_checked_target: "effect",
                show_when: "checked",
                target_name: "commit_logtime_activity_id"
              }
            ) do |builder|
              CommitLogTimeForm.new(builder)
            end
          end
        end

        private

        def available_statuses
          Status.pluck(:name, :id)
        end
      end
    end
  end
end
