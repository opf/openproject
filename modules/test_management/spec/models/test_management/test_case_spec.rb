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

RSpec.describe TestManagement::TestCase do
  let(:project) { create(:project) }

  it "uses a global numeric primary key" do
    first = create(:tm_test_case, project:)
    second = create(:tm_test_case, project:)

    expect(first.id).to be_a(Integer)
    expect(second.id).to be > first.id
  end

  it "formats the display id with the project prefix" do
    create(:tm_project_setting, project:, display_prefix: "DEMO")
    test_case = create(:tm_test_case, project:)

    expect(test_case.formatted_id).to eq("DEMO-#{test_case.id}")
  end

  it "accepts nested steps" do
    test_case = create(:tm_test_case, :with_steps, project:)
    expect(test_case.steps.count).to eq(2)
  end

  it "validates status and priority" do
    test_case = build(:tm_test_case, project:, status: "nope", priority: "extreme")
    expect(test_case).not_to be_valid
    expect(test_case.errors.attribute_names).to include(:status, :priority)
  end

  it "rejects duplicate automation references in the same project" do
    create(:tm_test_case, project:, automation_reference: "spec.ts#login")
    clash = build(:tm_test_case, project:, automation_reference: "spec.ts#login")

    expect(clash).not_to be_valid
    expect(clash.errors.attribute_names).to include(:automation_reference)
  end
end
