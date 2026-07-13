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

module Admin::Import::Jira::ImportRuns
  class TableComponent < OpPrimer::BorderBoxTableComponent
    columns :id, :status, :projects, :last_changed

    def initialize(jira:, **)
      @jira = jira
      super
    end

    def mobile_title
      Import::JiraImport.model_name.human(count: 2)
    end

    def row_class
      RowComponent
    end

    def has_actions?
      true
    end

    def has_header?
      rows.any?
    end

    def headers
      [
        [:id, { caption: I18n.t(:"admin.jira.run.title") }],
        [:status, { caption: Import::JiraImport.human_attribute_name(:status) }],
        [:projects, { caption: I18n.t(:"admin.jira.columns.projects") }],
        [:last_changed, { caption: I18n.t(:"admin.jira.columns.last_change") }]
      ]
    end

    def blank_title
      I18n.t(:"admin.jira.run.blank.title")
    end

    def blank_description
      I18n.t(:"admin.jira.run.blank.description")
    end

    def blank_icon
      :"arrow-down"
    end
  end
end
