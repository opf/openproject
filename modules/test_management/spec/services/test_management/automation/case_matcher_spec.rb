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

RSpec.describe TestManagement::Automation::CaseMatcher do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:other_project) { create(:project) }
  shared_let(:by_reference) do
    create(:tm_test_case, project:, title: "Sign in", automation_reference: "login.spec.ts#Login › signs in")
  end
  shared_let(:by_id) { create(:tm_test_case, project:, title: "Wrong password") }
  shared_let(:foreign) { create(:tm_test_case, project: other_project, title: "Foreign") }

  def record(**attrs)
    TestManagement::Automation::Record.new(raw_status: "passed", **attrs)
  end

  def match(rec, strategy: "auto")
    described_class.new(project:, strategy:).call([rec]).first
  end

  it "prefers the automation reference over an ID tag" do
    result = match(record(reference: "login.spec.ts#Login › signs in", tags: ["@TC-#{by_id.id}"]))

    expect(result.cases).to eq([by_reference])
    expect(result.matched_by).to eq("reference")
  end

  it "matches by the automation reference" do
    result = match(record(reference: "login.spec.ts#Login › signs in"))

    expect(result.cases).to eq([by_reference])
    expect(result.matched_by).to eq("reference")
  end

  it "matches ID tags and case ids" do
    expect(match(record(reference: "x#y", tags: ["@TC-#{by_id.id}"])).cases).to eq([by_id])
    expect(match(record(case_ids: [by_id.id.to_s])).cases).to eq([by_id])
  end

  it "does not match by title" do
    expect(match(record(title: "Wrong password")).cases).to be_empty
  end

  it "explains why nothing matched" do
    expect(match(record(reference: "nothing#here")).reason).to eq("no_matching_case")
    expect(match(record(case_ids: [foreign.id.to_s])).reason).to eq("case_not_in_project")
  end
end
