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
require_relative "../shared_context"

RSpec.describe AI::AssistantSkills::HealthCheck::Rules::StaleOpenDescendants do
  include_context "with a health check context"

  subject(:findings) { described_class.call(context) }

  context "with an open descendant that did not change for 90 days" do
    let!(:stale) { child_of(work_package, status: open_status, updated_at: 90.days.ago) }

    before do
      child_of(work_package, status: open_status)
      child_of(work_package, status: closed_status, updated_at: 90.days.ago)
    end

    it "reports only the stale open one" do
      expect(findings.size).to eq(1)
      expect(findings.first.evidence.pluck("work_package_id")).to eq([stale.id])
      expect(findings.first.text).to include("60 days")
    end
  end

  context "with more than five stale descendants" do
    before { 7.times { child_of(work_package, status: open_status, updated_at: 90.days.ago) } }

    it "shows five and counts the rest" do
      evidence = findings.first.evidence

      expect(evidence.size).to eq(6)
      expect(evidence.last).to eq("text" => "and 2 more")
    end
  end
end
