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

module Statuses
  class TableComponent < ::TableComponent
    def initial_sort
      %i[id asc]
    end

    def sortable?
      false
    end

    def columns
      headers.map(&:first)
    end

    def inline_create_link
      link_to new_status_path,
              aria: { label: t(:label_work_package_status_new) },
              class: "wp-inline-create--add-link",
              title: t(:label_work_package_status_new) do
        helpers.op_icon("icon icon-add")
      end
    end

    def empty_row_message
      I18n.t :no_results_title_text
    end

    def headers
      [
        [:name, { caption: Status.human_attribute_name(:name) }],
        [:color, { caption: Status.human_attribute_name(:color) }],
        [:done_ratio, { caption: WorkPackage.human_attribute_name(:done_ratio) }],
        [:default?, { caption: I18n.t("statuses.index.headers.is_default") }],
        [:closed?, { caption: I18n.t("statuses.index.headers.is_closed") }],
        [:readonly?, { caption: I18n.t("statuses.index.headers.is_readonly") }],
        [:excluded_from_totals?, { caption: I18n.t("statuses.index.headers.excluded_from_totals") }],
        [:sort, { caption: I18n.t(:label_sort) }]
      ]
    end
  end
end
