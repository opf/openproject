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
  ACTIVE = "active".freeze
  MY = "my".freeze
  FAVORED = "favored".freeze
  ARCHIVED = "archived".freeze
  ON_TRACK = "on_track".freeze
  OFF_TRACK = "off_track".freeze
  AT_RISK = "at_risk".freeze

  DEFAULT = ACTIVE

  class << self
    def query(id)
      case id
      when ACTIVE, nil
        static_query_active
      when MY
        static_query_my
      when FAVORED
        static_query_favored
      when ARCHIVED
        static_query_archived
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
      list_with(:"projects.lists.active") do |query|
        query.where("active", "=", OpenProject::Database::DB_VALUE_TRUE)
      end
    end

    def static_query_my
      list_with(:"projects.lists.my") do |query|
        query.where("member_of", "=", OpenProject::Database::DB_VALUE_TRUE)
      end
    end

    def static_query_favored
      list_with(:"projects.lists.favored") do |query|
        query.where("favored", "=", OpenProject::Database::DB_VALUE_TRUE)
      end
    end

    def static_query_archived
      list_with(:"projects.lists.archived") do |query|
        query.where("active", "=", OpenProject::Database::DB_VALUE_FALSE)
      end
    end

    def static_query_status_on_track
      list_with(:"activerecord.attributes.project.status_codes.on_track") do |query|
        query.where("project_status_code", "=", Project.status_codes[:on_track])
      end
    end

    def static_query_status_off_track
      list_with(:"activerecord.attributes.project.status_codes.off_track") do |query|
        query.where("project_status_code", "=", Project.status_codes[:off_track])
      end
    end

    def static_query_status_at_risk
      list_with(:"activerecord.attributes.project.status_codes.at_risk") do |query|
        query.where("project_status_code", "=", Project.status_codes[:at_risk])
      end
    end

    private

    def list_with(name)
      ProjectQuery.new(name: I18n.t(name)) do |query|
        query.order("lft" => "asc")
        query.select(*Setting.enabled_projects_columns, add_not_existing: false)

        yield query

        # This method is used to create static queries, so assume clean state after building
        query.clear_changes_information
      end
    end
  end
end
