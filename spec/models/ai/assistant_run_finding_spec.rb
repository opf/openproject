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
#++

require "spec_helper"

RSpec.describe AI::AssistantRunFinding do
  subject(:finding) { build(:ai_assistant_run_finding) }

  it "is valid with the factory defaults" do
    expect(finding).to be_valid
  end

  it "is invalid without evidence" do
    finding.evidence = []

    expect(finding).not_to be_valid
    expect(finding.errors.symbols_for(:evidence)).to include(:blank)
  end

  it "accepts a change set as a list of Automations actions on the work package itself" do
    finding.change_set = AI::Proposal.change_set_for({ "subject" => "New subject" })

    expect(finding).to be_valid
    expect(finding.change_target).to eq("self")
    expect(finding.change_action_keys).to eq(["subject"])
    expect(finding.change_value_for(:subject)).to eq("New subject")
  end

  it "rejects a change set for another target" do
    finding.change_set = AI::Proposal.change_set_for({ "subject" => "New subject" }, target: "parent")

    expect(finding).not_to be_valid
    expect(finding.errors.symbols_for(:change_set)).to include(:invalid)
  end

  it "rejects a change set without actions" do
    finding.change_set = { "target" => "self", "actions" => [] }

    expect(finding).not_to be_valid
  end

  it "rejects an unknown dismiss reason" do
    finding.dismiss_reason = "bored"

    expect(finding).not_to be_valid
    expect(finding.errors.symbols_for(:dismiss_reason)).to include(:inclusion)
  end

  describe ".by_severity" do
    let(:run) { create(:ai_assistant_run) }
    let!(:low) { create(:ai_assistant_run_finding, run:, severity: "low") }
    let!(:high) { create(:ai_assistant_run_finding, run:, severity: "high") }
    let!(:medium) { create(:ai_assistant_run_finding, run:, severity: "medium") }

    it "orders high, medium, low" do
      expect(run.findings.by_severity).to eq([high, medium, low])
    end
  end
end
