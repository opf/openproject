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

RSpec.describe AI::AssistantSkills::HealthCheck::Rules::ClosedWithOpenPrerequisites do
  include_context "with a health check context"

  subject(:findings) { described_class.call(context) }

  let(:work_package_status) { closed_status }
  let(:other) { create(:work_package, project:, status: open_status) }

  context "when an open work package blocks it" do
    before { create(:relation, from: other, to: work_package, relation_type: Relation::TYPE_BLOCKS) }

    it "reports a medium finding" do
      expect(findings.size).to eq(1)
      expect(findings.first).to have_attributes(severity: "medium", area: "relations")
      expect(findings.first.text).to include("blocked by")
    end
  end

  context "when it follows an open work package" do
    before { create(:relation, from: work_package, to: other, relation_type: Relation::TYPE_FOLLOWS) }

    it "reports a finding" do
      expect(findings.first.evidence.first["work_package_id"]).to eq(other.id)
    end
  end

  context "when it blocks an open work package" do
    before { create(:relation, from: work_package, to: other, relation_type: Relation::TYPE_BLOCKS) }

    it "reports nothing, because the other one waits for this one" do
      expect(findings).to be_empty
    end
  end

  context "when the open blocker is in a project the user cannot see" do
    let(:other) { create(:work_package, project: other_project, status: open_status) }

    before { create(:relation, from: other, to: work_package, relation_type: Relation::TYPE_BLOCKS) }

    it { is_expected.to be_empty }
  end
end
