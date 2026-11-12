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

RSpec.describe OpenProject::JournalFormatter::ProjectPhaseActive do
  describe "#render" do
    let(:id) { step.id }
    let(:key) { "project_life_cycle_step_#{id}_active" }
    let(:step) { build_stubbed(:project_phase, definition:) }

    subject(:result) { described_class.new(nil).render(key, values, html:) }

    before do
      allow(Project::Phase).to receive(:find_by).with(id: id.to_s).and_return(step)
    end

    shared_examples "test result" do
      context "with text output" do
        let(:html) { false }

        it { is_expected.to eq text_result }
      end

      context "with html output" do
        let(:html) { true }

        it { is_expected.to eq html_result }
      end
    end

    shared_examples "for phase changes" do
      context "when activated" do
        let(:values) { [false, true] }
        let(:text_result) { "The Phase activated" }
        let(:html_result) { "<strong>The Phase</strong> activated" }

        include_examples "test result"
      end

      context "when deactivated" do
        let(:values) { [true, false] }
        let(:text_result) { "The Phase deactivated" }
        let(:html_result) { "<strong>The Phase</strong> deactivated" }

        include_examples "test result"
      end

      context "when no change between truthy values" do
        let(:values) { [true, true] }
        let(:text_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end

      context "when no change between falsey values" do
        let(:values) { [nil, false] }
        let(:text_result) { nil }
        let(:html_result) { nil }

        include_examples "test result"
      end
    end

    context "without gates" do
      let(:definition) do
        build_stubbed(
          :project_phase_definition,
          name: "The Phase"
        )
      end

      include_examples "for phase changes"
    end

    context "with start gate" do
      let(:definition) do
        build_stubbed(
          :project_phase_definition,
          :with_start_gate,
          name: "The Phase"
        )
      end

      include_examples "for phase changes"
    end

    context "with end gate" do
      let(:definition) do
        build_stubbed(
          :project_phase_definition,
          :with_finish_gate,
          name: "The Phase"
        )
      end

      include_examples "for phase changes"
    end

    context "with both gates" do
      let(:definition) do
        build_stubbed(
          :project_phase_definition,
          :with_start_gate,
          :with_finish_gate,
          name: "The Phase"
        )
      end

      include_examples "for phase changes"
    end

    context "when phase was removed" do
      let(:id) { 42 }
      let(:step) { nil }

      let(:values) { [false, true] }
      let(:text_result) { nil }
      let(:html_result) { nil }

      include_examples "test result"
    end
  end
end
