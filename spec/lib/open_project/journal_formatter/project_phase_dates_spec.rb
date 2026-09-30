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

require "spec_helper"

RSpec.describe OpenProject::JournalFormatter::ProjectPhaseDates do
  describe "#render" do
    let(:id) { step.id }
    let(:key) { "project_life_cycle_step_#{id}_date_range" }
    let(:step) { build_stubbed(:project_phase, definition:) }

    let(:date_range_added) { [nil, date(29)..date(30)] }
    let(:date_range_start_changed) { [date(27)..date(30), date(29)..date(30)] }
    let(:date_range_end_changed) { [date(27)..date(28), date(27)..date(30)] }
    let(:date_range_changed) { [date(27)..date(28), date(29)..date(30)] }
    let(:date_range_removed) { [date(28)..date(29), nil] }

    subject(:result) { described_class.new(nil).render(key, values, html:) }

    before do
      allow(Project::Phase).to receive(:find_by).with(id: id.to_s).and_return(step)
    end

    def date(day) = Date.new(2025, 1, day)

    shared_examples "test result" do
      context "with plain output" do
        let(:html) { false }

        it { is_expected.to eq text_result }
      end

      context "with html output" do
        let(:html) { true }

        it { is_expected.to eq html_result }
      end
    end

    context "without gates" do
      let(:definition) do
        build_stubbed(
          :project_phase_definition,
          name: "The Phase"
        )
      end

      context "when date range added" do
        let(:values) { date_range_added }
        let(:text_result) { "The Phase set to 01/29/2025 - 01/30/2025" }
        let(:html_result) { "<strong>The Phase</strong> set to 01/29/2025 - 01/30/2025" }

        include_examples "test result"
      end

      context "when date range start changed" do
        let(:values) { date_range_start_changed }
        let(:text_result) do
          "The Phase changed from 01/27/2025 - 01/30/2025 to 01/29/2025 - 01/30/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> changed from 01/27/2025 - 01/30/2025 to 01/29/2025 - 01/30/2025"
        end

        include_examples "test result"
      end

      context "when date range end changed" do
        let(:values) { date_range_end_changed }
        let(:text_result) do
          "The Phase changed from 01/27/2025 - 01/28/2025 to 01/27/2025 - 01/30/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> changed from 01/27/2025 - 01/28/2025 to 01/27/2025 - 01/30/2025"
        end

        include_examples "test result"
      end

      context "when date range changed" do
        let(:values) { date_range_changed }
        let(:text_result) do
          "The Phase changed from 01/27/2025 - 01/28/2025 to 01/29/2025 - 01/30/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> changed from 01/27/2025 - 01/28/2025 to 01/29/2025 - 01/30/2025"
        end

        include_examples "test result"
      end

      context "when date range removed" do
        let(:values) { date_range_removed }
        let(:text_result) { "The Phase date deleted 01/28/2025 - 01/29/2025" }
        let(:html_result) { "<strong>The Phase</strong> date deleted <del>01/28/2025 - 01/29/2025</del>" }

        include_examples "test result"
      end

      context "when both date ranges absent" do
        let(:values) { [nil, nil] }
        let(:text_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end
    end

    context "with start gate" do
      let(:definition) do
        build_stubbed(
          :project_phase_definition,
          name: "The Phase",
          start_gate: true,
          start_gate_name: "The Start Gate"
        )
      end

      context "when date range added" do
        let(:values) { date_range_added }
        let(:text_result) do
          "The Phase set to 01/29/2025 - 01/30/2025. " \
            "The Start Gate set to 01/29/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> set to 01/29/2025 - 01/30/2025. " \
            "<strong>The Start Gate</strong> set to 01/29/2025"
        end

        include_examples "test result"
      end

      context "when date range start changed" do
        let(:values) { date_range_start_changed }
        let(:text_result) do
          "The Phase changed from 01/27/2025 - 01/30/2025 to 01/29/2025 - 01/30/2025. " \
            "The Start Gate changed from 01/27/2025 to 01/29/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> changed from 01/27/2025 - 01/30/2025 to 01/29/2025 - 01/30/2025. " \
            "<strong>The Start Gate</strong> changed from 01/27/2025 to 01/29/2025"
        end

        include_examples "test result"
      end

      context "when date range end changed" do
        let(:values) { date_range_end_changed }
        let(:text_result) do
          "The Phase changed from 01/27/2025 - 01/28/2025 to 01/27/2025 - 01/30/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> changed from 01/27/2025 - 01/28/2025 to 01/27/2025 - 01/30/2025"
        end

        include_examples "test result"
      end

      context "when date range changed" do
        let(:values) { date_range_changed }
        let(:text_result) do
          "The Phase changed from 01/27/2025 - 01/28/2025 to 01/29/2025 - 01/30/2025. " \
            "The Start Gate changed from 01/27/2025 to 01/29/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> changed from 01/27/2025 - 01/28/2025 to 01/29/2025 - 01/30/2025. " \
            "<strong>The Start Gate</strong> changed from 01/27/2025 to 01/29/2025"
        end

        include_examples "test result"
      end

      context "when date range removed" do
        let(:values) { date_range_removed }
        let(:text_result) do
          "The Phase date deleted 01/28/2025 - 01/29/2025. " \
            "The Start Gate date deleted 01/28/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> date deleted <del>01/28/2025 - 01/29/2025</del>. " \
            "<strong>The Start Gate</strong> date deleted <del>01/28/2025</del>"
        end

        include_examples "test result"
      end

      context "when both date ranges absent" do
        let(:values) { [nil, nil] }
        let(:text_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end
    end

    context "with end gate" do
      let(:definition) do
        build_stubbed(
          :project_phase_definition,
          name: "The Phase",
          finish_gate: true,
          finish_gate_name: "The End Gate"
        )
      end

      context "when date range added" do
        let(:values) { date_range_added }
        let(:text_result) do
          "The Phase set to 01/29/2025 - 01/30/2025. The End Gate set to 01/30/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> set to 01/29/2025 - 01/30/2025. <strong>The End Gate</strong> set to 01/30/2025"
        end

        include_examples "test result"
      end

      context "when date range start changed" do
        let(:values) { date_range_start_changed }
        let(:text_result) do
          "The Phase changed from 01/27/2025 - 01/30/2025 to 01/29/2025 - 01/30/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> changed from 01/27/2025 - 01/30/2025 to 01/29/2025 - 01/30/2025"
        end

        include_examples "test result"
      end

      context "when date range end changed" do
        let(:values) { date_range_end_changed }
        let(:text_result) do
          "The Phase changed from 01/27/2025 - 01/28/2025 to 01/27/2025 - 01/30/2025. " \
            "The End Gate changed from 01/28/2025 to 01/30/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> changed from 01/27/2025 - 01/28/2025 to 01/27/2025 - 01/30/2025. " \
            "<strong>The End Gate</strong> changed from 01/28/2025 to 01/30/2025"
        end

        include_examples "test result"
      end

      context "when date range changed" do
        let(:values) { date_range_changed }
        let(:text_result) do
          "The Phase changed from 01/27/2025 - 01/28/2025 to 01/29/2025 - 01/30/2025. " \
            "The End Gate changed from 01/28/2025 to 01/30/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> changed from 01/27/2025 - 01/28/2025 to 01/29/2025 - 01/30/2025. " \
            "<strong>The End Gate</strong> changed from 01/28/2025 to 01/30/2025"
        end

        include_examples "test result"
      end

      context "when date range removed" do
        let(:values) { date_range_removed }
        let(:text_result) do
          "The Phase date deleted 01/28/2025 - 01/29/2025. " \
            "The End Gate date deleted 01/29/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> date deleted <del>01/28/2025 - 01/29/2025</del>. " \
            "<strong>The End Gate</strong> date deleted <del>01/29/2025</del>"
        end

        include_examples "test result"
      end

      context "when both date ranges absent" do
        let(:values) { [nil, nil] }
        let(:text_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end
    end

    context "with both gates" do
      let(:definition) do
        build_stubbed(
          :project_phase_definition,
          name: "The Phase",
          start_gate: true,
          start_gate_name: "The Start Gate",
          finish_gate: true,
          finish_gate_name: "The End Gate"
        )
      end

      context "when date range added" do
        let(:values) { date_range_added }
        let(:text_result) do
          "The Phase set to 01/29/2025 - 01/30/2025. " \
            "The Start Gate set to 01/29/2025, and " \
            "The End Gate set to 01/30/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> set to 01/29/2025 - 01/30/2025. " \
            "<strong>The Start Gate</strong> set to 01/29/2025, and " \
            "<strong>The End Gate</strong> set to 01/30/2025"
        end

        include_examples "test result"
      end

      context "when date range start changed" do
        let(:values) { date_range_start_changed }
        let(:text_result) do
          "The Phase changed from 01/27/2025 - 01/30/2025 to 01/29/2025 - 01/30/2025. " \
            "The Start Gate changed from 01/27/2025 to 01/29/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> changed from 01/27/2025 - 01/30/2025 to 01/29/2025 - 01/30/2025. " \
            "<strong>The Start Gate</strong> changed from 01/27/2025 to 01/29/2025"
        end

        include_examples "test result"
      end

      context "when date range end changed" do
        let(:values) { date_range_end_changed }
        let(:text_result) do
          "The Phase changed from 01/27/2025 - 01/28/2025 to 01/27/2025 - 01/30/2025. " \
            "The End Gate changed from 01/28/2025 to 01/30/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> changed from 01/27/2025 - 01/28/2025 to 01/27/2025 - 01/30/2025. " \
            "<strong>The End Gate</strong> changed from 01/28/2025 to 01/30/2025"
        end

        include_examples "test result"
      end

      context "when date range changed" do
        let(:values) { date_range_changed }
        let(:text_result) do
          "The Phase changed from 01/27/2025 - 01/28/2025 to 01/29/2025 - 01/30/2025. " \
            "The Start Gate changed from 01/27/2025 to 01/29/2025, and " \
            "The End Gate changed from 01/28/2025 to 01/30/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> changed from 01/27/2025 - 01/28/2025 to 01/29/2025 - 01/30/2025. " \
            "<strong>The Start Gate</strong> changed from 01/27/2025 to 01/29/2025, and " \
            "<strong>The End Gate</strong> changed from 01/28/2025 to 01/30/2025"
        end

        include_examples "test result"
      end

      context "when date range removed" do
        let(:values) { date_range_removed }
        let(:text_result) do
          "The Phase date deleted 01/28/2025 - 01/29/2025. " \
            "The Start Gate date deleted 01/28/2025, and " \
            "The End Gate date deleted 01/29/2025"
        end
        let(:html_result) do
          "<strong>The Phase</strong> date deleted <del>01/28/2025 - 01/29/2025</del>. " \
            "<strong>The Start Gate</strong> date deleted <del>01/28/2025</del>, and " \
            "<strong>The End Gate</strong> date deleted <del>01/29/2025</del>"
        end

        include_examples "test result"
      end

      context "when both date ranges absent" do
        let(:values) { [nil, nil] }
        let(:text_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end
    end

    context "when phase was removed" do
      let(:id) { 42 }
      let(:step) { nil }

      let(:values) { date_range_added }
      let(:text_result) { nil }
      let(:html_result) { nil }

      include_examples "test result"
    end
  end
end
