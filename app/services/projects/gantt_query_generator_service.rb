#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Projects
  class GanttQueryGeneratorService
    DEFAULT_GANTT_QUERY ||=
      '{"c":["type","id","subject","status","project"],"tv":true,"hi":false,"g":"project"}'.freeze

    attr_reader :selected_project_ids

    def initialize(selected_project_ids)
      @selected_project_ids = selected_project_ids
    end

    def call
      # Read the raw query_props from the settings (filters and columns still serialized)
      params = params_from_settings.dup

      # Delete the parent filter
      params['f'] =
        if params['f']
          params['f'].reject { |filter| filter['n'] == 'project' }
        else
          []
        end

      # Ensure grouped by project
      params['g'] = 'project'
      params['hi'] = false

      # Ensure timeline visible
      params['tv'] = true

      # Add the parent filter
      params['f'] << { 'n' => 'project', 'o' => '=', 'v' => selected_project_ids }

      params.to_json
    end

    private

    def params_from_settings
      setting = Setting.project_gantt_query.presence || DEFAULT_GANTT_QUERY
      JSON.parse(setting)
    rescue JSON::JSONError => e
      Rails.logger.error "Failed to read project gantt view, resetting to default. Error was: #{e.message}"
      Setting.project_gantt_query = DEFAULT_GANTT_QUERY

      JSON.parse(DEFAULT_GANTT_QUERY)
    end
  end
end
