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

module Admin::Import::Jira
  class RowComponent < OpPrimer::BorderBoxRowComponent
    def name
      render(Primer::Beta::Link.new(href: admin_import_jira_path(model), font_weight: :bold)) do
        model.name || model.url
      end
    end

    def last_change
      last_run_updated_at = Import::JiraImport.where(jira_id: model.id).maximum(:updated_at)
      updated_at = last_run_updated_at || model.updated_at
      updated_at.nil? ? "" : time_ago(updated_at)
    end

    def time_ago(date_time)
      I18n.t(:"admin.jira.columns.label_ago", amount: distance_of_date_in_words(Time.zone.today, date_time))
    end

    def added
      helpers.format_date(model.created_at)
    end
  end
end
