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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  class WikiTableComponent < ::OpPrimer::BorderBoxTableComponent
    columns :title, :project_name, :sub_pages_count, :last_edited

    mobile_columns :title, :project_name
    mobile_labels :project_name

    main_column :title

    def sortable?
      false
    end

    def has_actions?
      false
    end

    def mobile_title
      I18n.t("wikis.index.title")
    end

    def headers
      [
        [:title,           { caption: I18n.t("wikis.index.column_name") }],
        [:project_name,    { caption: I18n.t("wikis.index.column_project") }],
        [:sub_pages_count, { caption: I18n.t("wikis.index.column_sub_pages") }],
        [:last_edited,     { caption: I18n.t("wikis.index.column_last_edited") }]
      ]
    end

    def sub_pages_counts
      @sub_pages_counts ||= WikiPage.where(parent_id: rows.map(&:id)).group(:parent_id).count
    end

    def blank_title
      I18n.t("wikis.index.no_results_title")
    end

    def blank_description
      I18n.t("wikis.index.no_results_description")
    end

    def blank_icon
      :book
    end
  end
end
