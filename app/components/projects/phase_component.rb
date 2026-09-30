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
  class PhaseComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include Projects::Phases::Shared

    def initialize(phase:, **)
      @phase = phase

      super(**)
    end

    def start_date
      if phase.start_date.present?
        helpers.format_date(phase.start_date)
      else
        helpers.t("js.label_no_start_date")
      end
    end

    def finish_date
      if phase.finish_date.present?
        helpers.format_date(phase.finish_date)
      else
        helpers.t("js.label_no_due_date")
      end
    end

    def display_start_gate?
      phase.start_gate? && phase.start_date.present?
    end

    def display_finish_gate?
      phase.finish_gate? && phase.finish_date.present?
    end

    def hover_card_data_args(gate:)
      raise ArgumentError, "gate must be either :start or :finish" unless %i[start finish].include?(gate)

      {
        hover_card_trigger_target: "trigger",
        hover_card_url: hover_card_project_phase_path(phase, gate:),
        test_selector: "phase-#{phase.id}-#{gate}-gate"
      }
    end

    private

    attr_reader :phase
  end
end
