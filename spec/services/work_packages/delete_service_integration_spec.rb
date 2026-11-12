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

RSpec.describe WorkPackages::DeleteService, "integration", type: :model do
  shared_let(:project) { create(:project_with_types) }
  shared_let(:role) do
    create(:project_role,
           permissions: %i[delete_work_packages view_work_packages add_work_packages manage_subtasks])
  end
  shared_let(:user) do
    create(:user, member_with_roles: { project => role })
  end

  shared_association_default(:author, factory_name: :user) { user }
  shared_association_default(:project_with_types) { project }
  shared_association_default(:priority) { create(:priority) }

  let(:instance) do
    described_class.new(user:,
                        model: deleted_work_package)
  end

  subject { instance.call }

  describe "deleting a child with estimated_hours set" do
    let(:parent) { create(:work_package, project:, subject: "parent") }
    let(:child) do
      create(:work_package,
             project:,
             parent:,
             subject: "child",
             estimated_hours: 123)
    end

    let(:deleted_work_package) { child }

    before do
      # Ensure estimated_hours is inherited
      WorkPackages::UpdateAncestorsService.new(user:, work_package: child).call(%i[estimated_hours])
      parent.reload
    end

    it "updates the parent estimated_hours" do
      expect(child.estimated_hours).to eq 123
      expect(parent.derived_estimated_hours).to eq 123
      expect(parent.estimated_hours).to be_nil

      expect(subject).to be_success, "Expected service call to be successful, but failed\n" \
                                     "service call errors: #{subject.errors.full_messages.inspect}"

      parent.reload

      expect(parent.estimated_hours).to be_nil
    end
  end

  describe "with a stale work package reference" do
    let!(:work_package) { create(:work_package, project:) }

    let(:deleted_work_package) { work_package }

    it "still destroys it" do
      # Cause lock version changes
      WorkPackage.where(id: work_package.id).update_all(lock_version: work_package.lock_version + 1)

      expect(subject).to be_success
      expect { work_package.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "deleting last child of an automatically scheduled parent" do
    let(:parent) { create(:work_package, subject: "parent", schedule_manually: false) }
    let(:child) { create(:work_package, subject: "child", parent:, schedule_manually: true) }

    let(:deleted_work_package) { child }

    it "switches the no-longer-parent work package to manual scheduling" do
      expect(subject).to be_success
      expect(parent.reload.schedule_manually).to be_truthy
      expect(subject.all_results).to include(parent)
    end
  end

  describe "deleting one of multiple children of an automatically scheduled parent" do
    let_work_packages(<<~TABLE)
      | hierarchy | MTWTFSS | scheduling mode
      | parent    | XXXX    | automatic
      |   child1  | XXX     | manual
      |   child2  |    X    | manual
    TABLE

    let(:deleted_work_package) { child1 }

    it "reschedules the parent to match the dates of the remaining children" do
      expect(subject).to be_success

      expect_work_packages(WorkPackage.all, <<~TABLE)
        | subject  | MTWTFSS | scheduling mode
        | parent   |    X    | automatic
        |   child2 |    X    | manual
      TABLE
      expect(subject.all_results).to contain_exactly(child1, parent)
    end
  end

  describe "deleting predecessor of a relation" do
    let(:predecessor) { create(:work_package, subject: "predecessor", schedule_manually: true) }
    let(:successor) { create(:work_package, subject: "successor", schedule_manually: false) }
    let!(:relation) { create(:follows_relation, predecessor:, successor:) }

    let(:deleted_work_package) { predecessor }

    it "switches the successor work package to manual scheduling" do
      expect(subject).to be_success
      expect(successor.reload.schedule_manually).to be_truthy
      expect(subject.all_results).to include(successor)
    end
  end

  describe "deleting parent having children being predecessors of other work packages" do
    let_work_packages(<<~TABLE)
      | hierarchy                     | MTWTFSS | scheduling mode | predecessors
      # these 3 work packages will be deleted when deleting the parent
      | parent                        | XXXX    | automatic       |
      |   child1                      | XXX     | manual          |
      |   child2                      |    X    | manual          |
      ### the following work packages will be affected by the deletion of the parent
      # this one will switch to manual scheduling
      | successor1_orphan             |    XX   | automatic       | child1
      # this one will keep automatic scheduling because it's a parent, and its child will switch to manual scheduling
      | successor2_parent             |     XX  | automatic       | child2
      |   successor2_child            |     XX  | automatic       |
      # this one will keep automatic scheduling because it has another predecessor, and will start at an earlier date
      | other_predecessor             | X       | manual          |
      | successor3_other_predecessor  |     XX  | automatic       | other_predecessor, child2
    TABLE

    let(:deleted_work_package) { parent }

    it "switches orphaned successors to manual scheduling, unless they have predecessors or children themselves" do
      expect(subject).to be_success

      expect_work_packages(WorkPackage.all, <<~TABLE)
        | subject                       | MTWTFSS | scheduling mode
        | successor1_orphan             |    XX   | manual

        | successor2_parent             |     XX  | automatic
        |   successor2_child            |     XX  | manual

        | other_predecessor             | X       | manual
        | successor3_other_predecessor  |  XX     | automatic
      TABLE
      expect(subject.all_results).to contain_exactly(
        # deleted work packages
        parent, child1, child2,
        # first successor switches to manual scheduling
        successor1_orphan,
        # second successor keeps automatic scheduling and its child switches to manual scheduling
        successor2_child,
        # third successor keeps automatic scheduling and is rescheduled to an earlier date
        successor3_other_predecessor
      )
    end
  end

  describe "with a notification" do
    let!(:work_package) { create(:work_package) }
    let!(:notification) do
      create(:notification,
             recipient: user,
             actor: user,
             resource: work_package)
    end

    let(:deleted_work_package) { work_package }

    it "deletes the notification" do
      expect(subject).to be_success
      expect { work_package.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { notification.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
