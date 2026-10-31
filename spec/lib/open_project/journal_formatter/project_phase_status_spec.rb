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

RSpec.describe OpenProject::JournalFormatter::ProjectPhaseStatus do
  describe "#render" do
    let(:id) { phase.id }
    let(:key) { "project_phase_#{id}_status" }
    let(:definition) { build_stubbed(:project_phase_definition, name: "The Phase") }
    let(:phase) { build_stubbed(:project_phase, definition:) }

    subject(:result) { described_class.new(nil).render(key, values, html:) }

    before do
      allow(Project::Phase).to receive(:find_by).with(id: id.to_s).and_return(phase)
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

    context "when the status changes from open to in progress" do
      let(:values) { %w[open in_progress] }
      let(:text_result) { "The Phase changed from Open to In progress" }
      let(:html_result) { "<strong>The Phase</strong> changed from Open to In progress" }

      include_examples "test result"
    end

    context "when the status changes from in progress to completed" do
      let(:values) { %w[in_progress completed] }
      let(:text_result) { "The Phase changed from In progress to Completed" }
      let(:html_result) { "<strong>The Phase</strong> changed from In progress to Completed" }

      include_examples "test result"
    end

    context "when the status changes from completed back to open" do
      let(:values) { %w[completed open] }
      let(:text_result) { "The Phase changed from Completed to Open" }
      let(:html_result) { "<strong>The Phase</strong> changed from Completed to Open" }

      include_examples "test result"
    end

    context "when the status does not change" do
      let(:values) { %w[open open] }
      let(:text_result) { nil }
      let(:html_result) { nil }

      include_examples "test result"
    end

    context "when the phase appears in the journal for the first time" do
      let(:values) { [nil, "open"] }
      let(:text_result) { nil }
      let(:html_result) { nil }

      include_examples "test result"
    end

    context "when the status is not a known one" do
      let(:values) { %w[open legacy] }
      let(:text_result) { "The Phase changed from Open to legacy" }
      let(:html_result) { "<strong>The Phase</strong> changed from Open to legacy" }

      include_examples "test result"
    end

    context "when the phase was removed" do
      let(:id) { 42 }
      let(:phase) { nil }

      let(:values) { %w[open in_progress] }
      let(:text_result) { nil }
      let(:html_result) { nil }

      include_examples "test result"
    end
  end
end
