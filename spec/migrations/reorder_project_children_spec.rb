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
require Rails.root.join("db/migrate/20220202140507_reorder_project_children.rb")

RSpec.describe ReorderProjectChildren, type: :model do
  # Silencing migration logs, since we are not interested in that during testing
  subject(:run_migration) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  shared_let(:parent_project_a) { create(:project, name: "ParentA") }
  shared_let(:parent_project_b) { create(:project, name: "ParentB") }

  shared_let(:child_a) { create(:project, name: "A", parent: parent_project_a) }
  shared_let(:child_b) { create(:project, name: "B", parent: parent_project_b) }
  shared_let(:child_c) { create(:project, name: "C", parent: parent_project_a) }
  shared_let(:child_d) { create(:project, name: "D", parent: parent_project_b) }
  shared_let(:child_f) { create(:project, name: "F", parent: parent_project_a) }

  let(:ordered) { Project.all.reorder(:lft) }

  before do
    # Update the names, including lower case to test case insensitivity
    parent_project_a.update_column(:name, "ParentLast")
    parent_project_b.update_column(:name, "ParentFirst")
    child_a.update_column(:name, "SecondChild")
    child_b.update_column(:name, "ThirdChild")
    child_c.update_column(:name, "firstChild")
    child_d.update_column(:name, "FourthChild")
    child_f.update_column(:name, "FifthChild")
  end

  it "corrects the order" do
    expect(ordered.pluck(:name)).to eq %w[ParentLast SecondChild firstChild FifthChild
                                          ParentFirst ThirdChild FourthChild]

    subject

    expect(ordered.reload.pluck(:name)).to eq %w[ParentFirst FourthChild ThirdChild
                                                 ParentLast FifthChild firstChild SecondChild]
  end
end
