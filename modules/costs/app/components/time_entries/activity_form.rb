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

module TimeEntries
  class ActivityForm < ApplicationForm
    form do |f|
      f.autocompleter(
        name: :activity_id,
        label: TimeEntry.human_attribute_name(:activity),
        required: false,
        include_blank: true,
        autocomplete_options: {
          placeholder: placeholder_text,
          focusDirectly: false,
          multiple: false,
          decorated: true,
          disabled: !project_or_entity_selected?,
          append_to: "#time-entry-dialog"
        }
      ) do |select|
        activities.each do |activity|
          select.option(value: activity.id, label: activity.name, selected: (model.activity_id == activity.id))
        end
      end
    end

    private

    delegate :project, :entity, to: :model

    def project_or_entity_selected?
      entity.present? || project.present?
    end

    def placeholder_text
      I18n.t("placeholder_activity_select_work_package_first") unless project_or_entity_selected?
    end

    def activities
      return [] if project.blank?

      TimeEntryActivity.active_in_project(project)
    end
  end
end
