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

RSpec.describe Relations::CreateService do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:user) { create(:admin) }

  let(:instance) { described_class.new(user:) }

  subject { instance.call(attributes) }

  before do
    set_non_working_week_days("saturday", "sunday")
  end

  context "when creating a successor relation to a child with an indirect predecessor" do
    let_work_packages(<<~TABLE)
      | hierarchy          | MTWTFSS   | scheduling mode | predecessors
      | parent_predecessor | XXX       | manual          |
      | parent             |     X..XX | automatic       | parent_predecessor
      |   child            |     X..XX | manual          |
      # this will become the predecessor of the child
      | child_predecessor  | X         | manual          |
    TABLE
    let(:attributes) do
      {
        "relation_type" => "follows",
        "from_id" => child.id,
        "to_id" => child_predecessor.id
      }
    end

    it "reschedules child and parent to start right after the indirect predecessor" do
      expect(subject).to be_success
      relation = subject.result
      expect(relation.predecessor).to eq(child_predecessor)
      expect(relation.successor).to eq(child)
      expect(subject.all_results).to contain_exactly(relation, child, parent)

      expect_work_packages_after_reload([parent_predecessor, parent, child, child_predecessor], <<~TABLE)
        | subject            | MTWTFSS  | scheduling mode
        | parent_predecessor | XXX      | manual
        | child_predecessor  | X        | manual
        | parent             |    XX..X | automatic
        |   child            |    XX..X | automatic
      TABLE
    end
  end

  context "when creating a successor relation between a predecessor and a parent being manually scheduled" do
    let_work_packages(<<~TABLE)
      | hierarchy          | MTWTFSS   | scheduling mode | predecessors
      | child_predecessor  | X         | manual          |
      | parent             |     X..XX | manual          |
      |   child            |  XX       | automatic       | child_predecessor
      # this will become the predecessor of the parent
      | parent_predecessor | XXX       | manual          |
    TABLE
    let(:attributes) do
      {
        "relation_type" => "follows",
        "from_id" => parent.id,
        "to_id" => parent_predecessor.id
      }
    end

    it "does not impact dates of an automatically scheduled child, because the parent is manually scheduled" do
      expect(subject).to be_success
      relation = subject.result
      expect(relation.predecessor).to eq(parent_predecessor)
      expect(relation.successor).to eq(parent)

      expect_work_packages_after_reload([parent_predecessor, parent, child, child_predecessor], <<~TABLE)
        | subject            | MTWTFSS  | scheduling mode
        | child_predecessor  | X         | manual          |
        | parent_predecessor | XXX       | manual          |
        | parent             |     X..XX | manual          |
        |   child            |  XX       | automatic       |
      TABLE
      expect(subject.all_results).to contain_exactly(relation)
    end
  end
end
