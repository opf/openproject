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

RSpec.describe AI::AssistantSkills::HealthCheck::Rules::ClosedWithOpenDescendants do
  include_context "with a health check context"

  subject(:findings) { described_class.call(context) }

  context "when the work package is closed and a grandchild is open" do
    let(:work_package_status) { closed_status }
    let!(:grandchild) { child_of(child_of(work_package, status: closed_status), status: open_status) }

    it "reports one high finding with the open descendant as evidence" do
      expect(findings.size).to eq(1)
      expect(findings.first).to have_attributes(severity: "high", area: "tree", rule_key: "closed_with_open_descendants")
      expect(findings.first.evidence.pluck("work_package_id")).to eq([grandchild.id])
    end
  end

  context "when the work package is open" do
    before { child_of(work_package, status: open_status) }

    it { is_expected.to be_empty }
  end

  context "when the only open descendant is in a project the user cannot see" do
    let(:work_package_status) { closed_status }

    before { child_of(work_package, status: open_status, project: other_project) }

    it "reports nothing, so the descendant does not leak" do
      expect(findings).to be_empty
    end
  end
end
