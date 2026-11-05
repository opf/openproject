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

RSpec.describe TestManagement::TestCases::SetAttributesService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_test_cases add_test_cases edit_test_cases] }) }

  def call(model, params, contract = TestManagement::TestCases::UpdateContract, acting: user)
    described_class.new(user: acting, model:, contract_class: contract).call(params)
  end

  it "defaults author, status and priority on create" do
    test_case = project.tm_test_cases.build
    result = call(test_case, { title: "New" }, TestManagement::TestCases::CreateContract)
    test_case.save!

    expect(result).to be_success
    expect(test_case.reload).to have_attributes(author: user, status: "ready", priority: "medium", updated_by: nil)
  end

  it "sets the last editor on update" do
    test_case = create(:tm_test_case, project:)
    editor = create(:user, member_with_permissions: { project => %i[view_test_cases edit_test_cases] })

    result = call(test_case, { title: "Changed" }, acting: editor)
    test_case.save!

    expect(result).to be_success
    expect(test_case.reload.updated_by).to eq(editor)
  end

  it "replaces the steps through nested attributes" do
    test_case = create(:tm_test_case, :with_steps, project:)
    kept, dropped = test_case.steps.to_a

    call(test_case, { steps_attributes: [{ id: kept.id, action: "Edited" },
                                         { id: dropped.id, _destroy: "1" },
                                         { position: 5, action: "Added" }] })
    test_case.save!

    expect(test_case.reload.steps.map(&:action)).to eq(["Edited", "Added"])
  end

  it "ignores blank new steps" do
    test_case = create(:tm_test_case, project:)

    call(test_case, { steps_attributes: [{ position: 0, action: "", expected_result: "" }] })
    test_case.save!

    expect(test_case.reload.steps).to be_empty
  end
end
