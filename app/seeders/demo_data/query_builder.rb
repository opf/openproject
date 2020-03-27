#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
module DemoData
  class QueryBuilder < ::Seeder
    attr_reader :config
    attr_reader :project

    def initialize(config, project)
      @config = config
      @project = project
    end

    def create!
      create_query if valid?
    end

    private

    ##
    # Don't seed queries specific to the backlogs plugin.
    def valid?
      backlogs_present? || !columns.include?("story_points")
    end

    def base_attributes
      {
        name: config[:name],
        user: User.admin.first,
        is_public: config[:is_public] != false,
        hidden: config[:hidden] == true,
        show_hierarchies: config[:hierarchy] == true,
        timeline_visible: config[:timeline] == true
      }
    end

    def create_query
      attr = base_attributes

      set_project! attr
      set_columns! attr
      set_sort_by! attr
      set_group_by! attr
      set_filters! attr
      set_display_representation! attr

      query = Query.create! attr

      create_menu_item query

      query
    end

    def create_menu_item(query)
      MenuItems::QueryMenuItem.create!(
        navigatable_id: query.id,
        name: SecureRandom.uuid,
        title: query.name
      )
    end

    def set_project!(attr)
      attr[:project] = project unless project.nil?
    end

    def set_display_representation!(attr)
      attr[:display_representation] = config[:display_representation] unless config[:display_representation].nil?
    end

    def set_columns!(attr)
      attr[:column_names] = columns unless columns.empty?
    end

    def columns
      @columns ||= Array(config[:columns]).map(&:to_s)
    end

    def set_sort_by!(attr)
      sort_by = config[:sort_by]

      attr[:sort_criteria] = [[sort_by, "asc"]] if sort_by
    end

    def set_group_by!(attr)
      group_by = config[:group_by]

      attr[:group_by] = group_by if group_by
    end

    def set_filters!(query_attr)
      fs = filters

      query_attr[:filters] = [fs] unless fs.empty?
    end

    def filters
      filters = {}

      set_status_filter! filters
      set_version_filter! filters
      set_type_filter! filters
      set_parent_filter! filters

      filters
    end

    def set_status_filter!(filters)
      status = String(config[:status])

      filters[:status_id] = { operator: "o" } if status == "open"
    end

    def set_version_filter!(filters)
      if version = config[:version].presence
        filters[:version_id] = {
          operator: "=",
          values: [Version.find_by(name: version).id]
        }
      end
    end

    def set_type_filter!(filters)
      types = Array(config[:type]).map do |name|
        Type.find_by(name: translate_with_base_url(name))
      end

      if !types.empty?
        filters[:type_id] = {
          operator: "=",
          values: types.map(&:id).map(&:to_s)
        }
      end
    end

    def set_parent_filter!(filters)
      if parent_filter_value = config[:parent].presence
        filters[:parent] = {
          operator: "=",
          values: [parent_filter_value]
        }
      end
    end

    def backlogs_present?
      @backlogs_present = defined? OpenProject::Backlogs if @backlogs_present.nil?

      @backlogs_present
    end
  end
end
