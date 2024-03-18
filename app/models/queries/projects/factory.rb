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
  STATIC_ACTIVE = 'active'.freeze
  STATIC_MY = 'my'.freeze
  STATIC_ARCHIVED = 'archived'.freeze
  STATIC_ON_TRACK = 'on_track'.freeze
  STATIC_OFF_TRACK = 'off_track'.freeze
  STATIC_AT_RISK = 'at_risk'.freeze

  class << self
    def find(id, params:, user:)
      find_and_update_static_query(id, params, user) || find_and_update_persisted_query(id, params, user)
    end

    def static_query(id)
      case id
      when STATIC_ACTIVE, nil
        static_query_active
      when STATIC_MY
        static_query_my
      when STATIC_ARCHIVED
        static_query_archived
      when STATIC_ON_TRACK
        static_query_status_on_track
      when STATIC_OFF_TRACK
        static_query_status_off_track
      when STATIC_AT_RISK
        static_query_status_at_risk
      end
    end

    def static_query_active
      list_with(:'projects.lists.active') do |query|
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
        query.order('lft' => 'asc')
        query.select(*(['name'] + Setting.enabled_projects_columns).uniq, add_not_existing: false)

        yield query
      end
    end

    def find_and_update_static_query(id, params, user)
      query = static_query(id)

      return unless query

      if params.any?
        new_query(query, params, user)
      else
        query
      end
    end

    def find_and_update_persisted_query(id, params, user)
      query = Queries::Projects::ProjectQuery.where(user:).find_by(id:)

      return unless query

      if params.any?
        update_query(query, params, user)
      else
        query
      end
    end

    def new_query(source_query, params, user)
      update_query(Queries::Projects::ProjectQuery.new(source_query.attributes.slice('filters', 'orders', 'selects')),
                   params,
                   user)
    end

    def update_query(query, params, user)
      Queries::Projects::ProjectQueries::SetAttributesService
        .new(user:,
             model: query,
             contract_class: Queries::Projects::ProjectQueries::LoadingContract)
        .call(params)
        .result
    end
  end
end
