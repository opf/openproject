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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects
  module Phases
    class HoverCardComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include Projects::Phases::Shared

      attr_reader :phase

      def initialize(phase:, gate:)
        raise ArgumentError, "gate must be either 'start' or 'finish'" unless %w[start finish].include?(gate)

        super

        @phase = phase
        @gate = gate.to_sym
      end

      def phase_gate_name
        case @gate
        when :start
          @phase.start_gate? ? @phase.start_gate_name : nil
        else
          @phase.finish_gate? ? @phase.finish_gate_name : nil
        end
      end

      def phase_gate_date
        date = case @gate
               when :start
                 @phase.start_date
               else
                 @phase.finish_date
               end

        helpers.format_date(date)
      end
    end
  end
end
