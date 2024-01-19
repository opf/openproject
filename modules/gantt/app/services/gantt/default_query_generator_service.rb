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

module Gantt
  class DefaultQueryGeneratorService
    PROJECT_DEFAULT_COLUMNS = %w[id type subject status startDate dueDate duration].freeze
    GLOBAL_DEFAULT_COLUMNS = %w[id type subject status startDate dueDate duration project].freeze

    DEFAULT_PARAMS =
      {
        tll: '{"left":"startDate","right":"dueDate","farRight":"subject"}',
        tzl: "auto",
        tv: true,
        hi: true
      }.to_json.freeze

    attr_reader :with_project_context

    class << self
      def default_gantt_query(with_project_context)
        default_with_filter = JSON
                                .parse(Gantt::DefaultQueryGeneratorService::DEFAULT_PARAMS)

        default_with_filter['c'] = if with_project_context
                                     Gantt::DefaultQueryGeneratorService::PROJECT_DEFAULT_COLUMNS
                                   else
                                     Gantt::DefaultQueryGeneratorService::GLOBAL_DEFAULT_COLUMNS
                                   end

        milestone_ids = ::Type.milestone.pluck(:id).map(&:to_s)
        if milestone_ids.any?
          default_with_filter['f'] = [{ 'n' => 'type', 'o' => '=', 'v' => milestone_ids }]
        end

        default_with_filter
      end
    end

    def initialize(with_project_context:)
      @with_project_context = with_project_context
    end

    def call
      params = self.class.default_gantt_query(@with_project_context)

      params.to_json
    end
  end
end
