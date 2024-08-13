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

module ::Gantt
  class DefaultQueryGeneratorService
    DEFAULT_QUERY = :all_open
    QUERY_OPTIONS = [
      DEFAULT_QUERY,
      :milestones
    ].freeze

    PROJECT_DEFAULT_COLUMNS = %w[id type subject status startDate dueDate duration].freeze
    GLOBAL_DEFAULT_COLUMNS = %w[id project type subject status startDate dueDate duration].freeze

    DEFAULT_PARAMS =
      {
        tll: '{"left":"startDate","right":"dueDate","farRight":"subject"}',
        tzl: "auto",
        tv: true,
        hi: true,
        t: "start_date:asc"
      }.to_json.freeze

    attr_reader :project

    def initialize(with_project:)
      @project = with_project
    end

    def call(query_key: DEFAULT_QUERY)
      params =
        case query_key
        when DEFAULT_QUERY
          self.class.all_open_query(@project)
        when :milestones
          self.class.milestones_query(@project)
        end

      return if params.nil?

      { query_props: params.to_json, name: query_key }
    end

    class << self
      def all_open_query(project)
        default_with_filter = add_columns(project)

        default_with_filter["f"] = [{ "n" => "status", "o" => "o", "v" => [] }]

        default_with_filter
      end

      def milestones_query(project)
        default_with_filter = add_columns(project)

        milestones = milestone_ids(project)
        return if milestones.empty?

        default_with_filter["f"] = [{ "n" => "type", "o" => "=", "v" => milestones }]
        default_with_filter
      end

      def add_columns(project)
        default_with_filter = JSON
          .parse(Gantt::DefaultQueryGeneratorService::DEFAULT_PARAMS)

        default_with_filter["c"] = if project.present?
                                     Gantt::DefaultQueryGeneratorService::PROJECT_DEFAULT_COLUMNS
                                   else
                                     Gantt::DefaultQueryGeneratorService::GLOBAL_DEFAULT_COLUMNS
                                   end

        default_with_filter
      end

      def milestone_ids(project)
        if project.present?
          ::Type.milestone.enabled_in(project.id).pluck(:id).map(&:to_s)
        else
          ::Type.milestone.pluck(:id).map(&:to_s)
        end
      end

      def phase_ids(project)
        if project.present?
          ::Type
            .enabled_in(project.id)
            .where(name: I18n.t("seeds.standard.types.item_2.name", default: "Phase"))
            .pluck(:id)
            .map(&:to_s)
        else
          ::Type.where(name: "Phase").pluck(:id).map(&:to_s)
        end
      end
    end
  end
end
