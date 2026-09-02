# frozen_string_literal: true

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
# ++

module Backlogs
  module SprintReports
    module Widgets
      class WorkPackageOverview
        class BreakdownBlock < ApplicationComponent
          include OpPrimer::ComponentHelpers

          attr_reader :heading, :show_all_href, :count_color

          def initialize(heading:, show_all_href:, count_color: :default)
            super

            @heading = heading
            @show_all_href = show_all_href
            @count_color = count_color
          end

          renders_one :count, ->(**system_arguments) do
            text_with_defaults(system_arguments, tag: :p, mb: 0, font_size: 1, font_weight: :bold, color: count_color)
          end
          renders_one :story_points, ->(**system_arguments) do
            text_with_defaults(system_arguments, tag: :p, color: :muted, mb: 2)
          end

          private

          def text_with_defaults(system_arguments, defaults)
            Primer::Beta::Text.new(**system_arguments.reverse_merge(defaults))
          end
        end
      end
    end
  end
end
