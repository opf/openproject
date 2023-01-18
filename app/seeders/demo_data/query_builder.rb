#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
module DemoData
  class QueryBuilder < ::Seeder
    attr_reader :config, :project

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
        user: User.admin.user.first,
        public: config.fetch(:public, true),
        starred: config.fetch(:starred, false),
        show_hierarchies: config.fetch(:hierarchy, false),
        timeline_visible: config.fetch(:timeline, false),
        include_subprojects: true
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

      create_view(query) unless config[:hidden]

      query
    end

    def create_view(query)
      type = config.fetch(:module, 'work_packages_table')
      View.create!(
        type:,
        query:
      )

      # Save information that a view has been seeded.
      # This information can be used for example in the onboarding tour
      Setting["demo_view_of_type_#{type}_seeded"] = 'true'
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
      set_assignee_filter! filters

      filters
    end

    def set_status_filter!(filters)
      filters[:status_id] = { operator: "o" } if String(config[:status]) == "open"
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
      types = Type
                .where(name: Array(config[:type]).map { |name| translate_with_base_url(name) })
                .pluck(:id)

      if types.any?
        filters[:type_id] = {
          operator: "=",
          values: types.map(&:to_s)
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

    def set_assignee_filter!(filters)
      users = Array(config[:assignee])
                .map(&:split)
                .inject(User.user.none) do |scope, (firstname, lastname)|
                  scope.or(User.user.where(firstname:, lastname:))
                end
                .pluck(:id)

      if users.any?
        filters[:assigned_to_id] = {
          operator: "=",
          values: users.map(&:to_s)
        }
      end
    end

    def backlogs_present?
      @backlogs_present = defined? OpenProject::Backlogs if @backlogs_present.nil?

      @backlogs_present
    end
  end
end
