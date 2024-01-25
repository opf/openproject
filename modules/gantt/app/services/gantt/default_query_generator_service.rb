#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
    QUERY_MAPPINGS = {
      DEFAULT_QUERY => I18n.t('queries.all_open'),
      :timeline => I18n.t('queries.timeline'),
      :milestones => I18n.t('queries.milestones')
    }.freeze
    QUERY_OPTIONS = QUERY_MAPPINGS.keys

    PROJECT_DEFAULT_COLUMNS = %w[id type subject status startDate dueDate duration].freeze
    GLOBAL_DEFAULT_COLUMNS = %w[id type subject status startDate dueDate duration project].freeze

    DEFAULT_PARAMS =
      {
        tll: '{"left":"startDate","right":"dueDate","farRight":"subject"}',
        tzl: "auto",
        tv: true,
        hi: true,
        t: 'start_date:asc'
      }.to_json.freeze

    attr_reader :with_project_context

    def initialize(with_project_context:)
      @with_project_context = with_project_context
    end

    def call(query_key: DEFAULT_QUERY)
      case query_key
      when DEFAULT_QUERY
        params = self.class.all_open_query(@with_project_context)
      when :timeline
        params = self.class.timeline_query(@with_project_context)
      when :milestones
        params = self.class.milestones_query(@with_project_context)
      else
        return
      end

      params.to_json
    end

    class << self
      def all_open_query(with_project_context)
        default_with_filter = add_columns(with_project_context)

        default_with_filter['f'] = [{ 'n' => 'status', 'o' => 'o', 'v' => [] }]

        default_with_filter
      end

      def timeline_query(with_project_context)
        default_with_filter = add_columns(with_project_context)

        milestones = milestone_ids
        phase = ::Type.where(name: 'Phase').pluck(:id).map(&:to_s)

        type_filter_values = milestones.concat(phase)
        if type_filter_values.any?
          default_with_filter['f'] = [{ 'n' => 'type', 'o' => '=', 'v' => type_filter_values }]
        end

        default_with_filter
      end

      def milestones_query(with_project_context)
        default_with_filter = add_columns(with_project_context)

        milestones = milestone_ids
        if milestone_ids.any?
          default_with_filter['f'] = [{ 'n' => 'type', 'o' => '=', 'v' => milestones }]
        end

        default_with_filter
      end

      def add_columns(with_project_context)
        default_with_filter = JSON
                                .parse(Gantt::DefaultQueryGeneratorService::DEFAULT_PARAMS)

        default_with_filter['c'] = if with_project_context
                                     Gantt::DefaultQueryGeneratorService::PROJECT_DEFAULT_COLUMNS
                                   else
                                     Gantt::DefaultQueryGeneratorService::GLOBAL_DEFAULT_COLUMNS
                                   end

        default_with_filter
      end

      def milestone_ids
        ::Type.milestone.pluck(:id).map(&:to_s)
      end
    end
  end
end
