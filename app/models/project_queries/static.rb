# frozen_string_literal: true

# -- copyright
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
# ++

class ProjectQueries::Static
  ACTIVE = "active"
  MY = "my"
  FAVORITED = "favorited"
  ARCHIVED = "archived"
  ON_TRACK = "on_track"
  OFF_TRACK = "off_track"
  AT_RISK = "at_risk"

  ACTIVE_PORTFOLIOS = "active_portfolios"
  MY_PORTFOLIOS = "my_portfolios"
  FAVORITED_PORTFOLIOS = "favorited_portfolios"
  ARCHIVED_PORTFOLIOS = "archived_portfolios"

  DEFAULT = ACTIVE

  class << self
    def query(id)
      case id
      when ACTIVE, nil
        static_query_active
      when ACTIVE_PORTFOLIOS
        static_query_active_portfolios
      when MY
        static_query_my
      when MY_PORTFOLIOS
        static_query_my_portfolios
      when FAVORITED
        static_query_favorited
      when FAVORITED_PORTFOLIOS
        static_query_favorited_portfolios
      when ARCHIVED
        static_query_archived
      when ARCHIVED_PORTFOLIOS
        static_query_archived_portfolios
      when ON_TRACK
        static_query_status_on_track
      when OFF_TRACK
        static_query_status_off_track
      when AT_RISK
        static_query_status_at_risk
      end
    end

    private

    def static_query_active
      static_query("active", "=", OpenProject::Database::DB_VALUE_TRUE, name: :"projects.lists.active")
    end

    def static_query_active_portfolios
      static_query("active", "=", OpenProject::Database::DB_VALUE_TRUE, name: :"portfolios.lists.active")
    end

    def static_query_my
      static_query("member_of", "=", OpenProject::Database::DB_VALUE_TRUE, name: :"projects.lists.my")
    end

    def static_query_my_portfolios
      static_query("member_of", "=", OpenProject::Database::DB_VALUE_TRUE, name: :"portfolios.lists.my")
    end

    def static_query_favorited
      static_query("favorited", "=", OpenProject::Database::DB_VALUE_TRUE, name: :"projects.lists.favorited")
    end

    def static_query_favorited_portfolios
      static_query("favorited", "=", OpenProject::Database::DB_VALUE_TRUE, name: :"portfolios.lists.favorited")
    end

    def static_query_archived
      static_query("active", "=", OpenProject::Database::DB_VALUE_FALSE, name: :"projects.lists.archived")
    end

    def static_query_archived_portfolios
      static_query("active", "=", OpenProject::Database::DB_VALUE_FALSE, name: :"portfolios.lists.archived")
    end

    def static_query_status_on_track
      static_query("project_status_code", "=", Project.status_codes[:on_track],
                   name: :"activerecord.attributes.project.status_codes.on_track")
    end

    def static_query_status_off_track
      static_query("project_status_code", "=", Project.status_codes[:off_track],
                   name: :"activerecord.attributes.project.status_codes.off_track")
    end

    def static_query_status_at_risk
      static_query("project_status_code", "=", Project.status_codes[:at_risk],
                   name: :"activerecord.attributes.project.status_codes.at_risk")
    end

    def static_query(field, operator, value, name:)
      ProjectQuery.new(name: I18n.t(name)) do |query|
        query.order("lft" => "asc")
        query.select(*Setting.enabled_projects_columns, add_not_existing: false)
        query.where(field, operator, value)

        # This method is used to create static queries, so assume clean state after building
        query.clear_changes_information
      end
    end
  end
end
