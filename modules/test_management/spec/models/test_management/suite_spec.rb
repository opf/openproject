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

RSpec.describe TestManagement::Suite do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let!(:root) { create(:tm_suite, project:, name: "Accounts") }
  let!(:child) { create(:tm_suite, project:, parent: root, name: "Sign in") }
  let!(:grandchild) { create(:tm_suite, project:, parent: child, name: "Two factor") }

  it "requires a name unique among siblings" do
    expect(build(:tm_suite, project:, name: "")).not_to be_valid
    expect(build(:tm_suite, project:, name: "Accounts")).not_to be_valid
    expect(build(:tm_suite, project:, parent: root, name: "Sign in")).not_to be_valid
    expect(build(:tm_suite, project:, parent: child, name: "Sign in")).to be_valid
  end

  it "enforces root-folder uniqueness at the database (NULL parent_id)" do
    now = Time.current
    expect do
      described_class.insert!({
                                project_id: project.id,
                                parent_id: nil,
                                name: "Accounts",
                                position: 0,
                                created_at: now,
                                updated_at: now
                              })
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "returns subtree ids" do
    expect(described_class.subtree_ids(project, [root.id])).to contain_exactly(root.id, child.id, grandchild.id)
    expect(described_class.subtree_ids(project, [child.id])).to contain_exactly(child.id, grandchild.id)
  end

  it "builds the folder path" do
    expect(grandchild.path_name).to eq("Accounts / Sign in / Two factor")
    expect(grandchild.path_name(" > ")).to eq("Accounts > Sign in > Two factor")
  end

  it "destroys subfolders and unfiles their cases" do
    test_case = create(:tm_test_case, project:, suite: grandchild)
    root.destroy

    expect(described_class.where(project:)).to be_empty
    expect(test_case.reload.suite_id).to be_nil
  end

  it "orders by position then name and exposes roots" do
    expect(described_class.where(project:).roots).to contain_exactly(root)
  end
end
