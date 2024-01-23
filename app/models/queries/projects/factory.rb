# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

class Queries::Projects::Factory
  class << self
    def find(id)
      static_query(id) || Queries::Projects::ProjectQuery.find(id)
    end

    def static_query(id)
      case id
      when 'all'
        static_query_all
      when 'my'
        static_query_my
      when 'archived'
        static_query_archived
      when 'on_track'
        static_query_status_on_track
      when 'off_track'
        static_query_status_off_track
      when 'at_risk'
        static_query_status_at_risk
      when nil
        list_with(:'projects.lists.all')
      end
    end

    def static_query_all
      list_with(:'projects.lists.all') do |query|
        query.where('active', '=', OpenProject::Database::DB_VALUE_TRUE)
      end
    end

    def static_query_my
      list_with(:'projects.lists.my') do |query|
        query.where('member_of', '=', OpenProject::Database::DB_VALUE_TRUE)
      end
    end

    def static_query_archived
      list_with(:'projects.lists.archived') do |query|
        query.where('active', '=', OpenProject::Database::DB_VALUE_FALSE)
      end
    end

    def static_query_status_on_track
      list_with(:'activerecord.attributes.project.status_codes.on_track') do |query|
        query.where('project_status_code', '=', Project.status_codes[:on_track])
      end
    end

    def static_query_status_off_track
      list_with(:'activerecord.attributes.project.status_codes.off_track') do |query|
        query.where('project_status_code', '=', Project.status_codes[:off_track])
      end
    end

    def static_query_status_at_risk
      list_with(:'activerecord.attributes.project.status_codes.at_risk') do |query|
        query.where('project_status_code', '=', Project.status_codes[:at_risk])
      end
    end

    private

    def list_with(name)
      Queries::Projects::ProjectQuery.new(name: I18n.t(name)) do |query|
        yield query if block_given?
      end
    end
  end
end
