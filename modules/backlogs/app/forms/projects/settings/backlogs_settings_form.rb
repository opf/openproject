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

module Projects
  module Settings
    class BacklogsSettingsForm < ApplicationForm
      form do |f|
        f.autocompleter(
          name: :done_status_ids,
          label: attribute_name(:statuses_considered_closed),
          caption: I18n.t(:"backlogs.statuses_considered_closed_caption"),
          autocomplete_options: {
            multiple: true,
            closeOnSelect: false,
            clearable: false,
            decorated: true,
            data: {
              test_selector: "done_status_ids_autocomplete"
            }
          }
        ) do |list|
          available_statuses.each do |label, value, is_closed|
            list.option(
              label:,
              value:,
              selected: value.in?(model.done_status_ids),
              disabled: is_closed
            )
          end
        end

        f.autocompleter(
          name: :backlog_excluded_type_ids,
          label: attribute_name(:backlog_excluded_types),
          caption: I18n.t(:"backlogs.excluded_work_package_types_caption"),
          autocomplete_options: {
            multiple: true,
            closeOnSelect: false,
            clearable: false,
            decorated: true,
            data: {
              test_selector: "backlog_excluded_type_ids_autocomplete"
            }
          }
        ) do |list|
          available_types.each do |label, value|
            active = value.in?(model.backlog_excluded_type_ids)

            list.option(
              label:,
              value:,
              selected: active
            )
          end
        end

        f.submit(scheme: :primary, name: :apply, label: I18n.t(:button_save))
      end

      private

      def available_statuses
        Status.pluck(:name, :id, :is_closed)
      end

      def available_types
        model.types.pluck(:name, :id)
      end
    end
  end
end
