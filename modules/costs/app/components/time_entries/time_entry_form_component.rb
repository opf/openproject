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

module TimeEntries
  class TimeEntryFormComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    options time_entry: nil,
            limit_to_project_id: nil,
            show_user: true,
            show_work_package: true

    private

    delegate :project, :work_package, to: :time_entry

    def form_options
      base = {
        model: time_entry,
        data: {
          turbo: true,
          "time-entry-target" => "form",
          refresh_form_url: refresh_form_time_entries_path
        },
        id: "time-entry-form",
        html: { autocomplete: "off" }
      }

      if time_entry.persisted?
        base.deep_merge({
                          url: time_entry_path(time_entry),
                          method: :patch,
                          data: {
                            refresh_form_url: refresh_form_time_entry_path(time_entry)
                          }
                        })
      else

        base.deep_merge({
                          url: time_entries_path,
                          method: :post,
                          data: {
                            refresh_form_url: refresh_form_time_entries_path
                          }
                        })
      end
    end
  end
end
