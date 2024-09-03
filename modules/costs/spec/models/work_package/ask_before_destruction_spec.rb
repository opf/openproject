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

RSpec.describe WorkPackage do
  let(:work_package) do
    create(:work_package, project:,
                          status:)
  end
  let(:work_package2) do
    create(:work_package, project: project2,
                          status:)
  end
  let(:user) { create(:user) }

  let(:type) { create(:type_standard) }
  let(:project) { create(:project, types: [type]) }
  let(:project2) { create(:project, types: [type]) }
  let(:role) { create(:project_role) }
  let(:role2) { create(:project_role) }
  let(:member) do
    create(:member, principal: user,
                    roles: [role])
  end
  let(:member2) do
    create(:member, principal: user,
                    roles: [role2],
                    project: work_package2.project)
  end
  let(:status) { create(:status) }
  let(:priority) { create(:priority) }
  let(:cost_type) { create(:cost_type) }
  let(:cost_entry) do
    create(:cost_entry, work_package:,
                        project: work_package.project,
                        cost_type:)
  end
  let(:cost_entry2) do
    create(:cost_entry, work_package: work_package2,
                        project: work_package2.project,
                        cost_type:)
  end

  describe "#cleanup_action_required_before_destructing?" do
    describe "w/ the work package having a cost entry" do
      before do
        work_package
        cost_entry
      end

      it "is true" do
        expect(WorkPackage.cleanup_action_required_before_destructing?(work_package)).to be_truthy
      end
    end

    describe "w/ two work packages having a cost entry" do
      before do
        work_package
        cost_entry
        cost_entry2
      end

      it "is true" do
        expect(WorkPackage.cleanup_action_required_before_destructing?([work_package, work_package2])).to be_truthy
      end
    end

    describe "w/o the work package having a cost entry" do
      before do
        work_package
      end

      it "is false" do
        expect(WorkPackage.cleanup_action_required_before_destructing?(work_package)).to be_falsey
      end
    end
  end

  describe "#associated_classes_to_address_before_destructing?" do
    describe "w/ the work package having a cost entry" do
      before do
        work_package
        cost_entry
      end

      it "is have 'CostEntry' as class to address" do
        expect(WorkPackage.associated_classes_to_address_before_destruction_of(work_package)).to eq([CostEntry])
      end
    end

    describe "w/o the work package having a cost entry" do
      before do
        work_package
      end

      it "is empty" do
        expect(WorkPackage.associated_classes_to_address_before_destruction_of(work_package)).to be_empty
      end
    end
  end

  describe "#cleanup_associated_before_destructing_if_required" do
    before do
      work_package.save!

      cost_entry
    end

    describe "w/o a cleanup being necessary" do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, action: "reassign") }

      before do
        cost_entry.destroy
      end

      it "returns true" do
        expect(action).to be_truthy
      end
    end

    describe 'w/ "destroy" as action' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, action: "destroy") }

      it "returns true" do
        expect(action).to be_truthy
      end

      it "does not touch the cost_entry" do
        action

        cost_entry.reload
        expect(cost_entry.work_package_id).to eq(work_package.id)
      end
    end

    describe "w/o an action" do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user) }

      it "returns true" do
        expect(action).to be_truthy
      end

      it "does not touch the cost_entry" do
        action

        cost_entry.reload
        expect(cost_entry.work_package_id).to eq(work_package.id)
      end
    end

    describe 'w/ "nullify" as action' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, action: "nullify") }

      it "returns false" do
        expect(action).to be_falsey
      end

      it "does not alter the work_package_id of all cost entries" do
        action

        cost_entry.reload
        expect(cost_entry.work_package_id).to eq(work_package.id)
      end

      it "sets an error on work packages" do
        action

        expect(work_package.errors[:base]).to eq([I18n.t(:"activerecord.errors.models.work_package.nullify_is_not_valid_for_cost_entries")])
      end
    end

    describe 'with "reassign" as action ' \
             "with reassigning to a valid work_package" do
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, action: "reassign",
                                                                                          reassign_to_id: work_package2.id)
      end

      before do
        work_package2.save!
        role2.add_permission! :edit_cost_entries
        role2.save!
        member2.save!
      end

      it "returns true" do
        expect(action).to be_truthy
      end

      it "sets the work_package_id of all cost entries to the new work package" do
        action

        cost_entry.reload
        expect(cost_entry.work_package_id).to eq(work_package2.id)
      end

      it "sets the project_id of all cost entries to the new work package's project" do
        action

        cost_entry.reload
        expect(cost_entry.project_id).to eq(work_package2.project_id)
      end
    end

    describe 'with "reassign" as action ' \
             "with reassigning to a work_package the user is not allowed to see" do
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, action: "reassign",
                                                                                          reassign_to_id: work_package2.id)
      end

      before do
        work_package2.save!
      end

      it "returns true" do
        expect(action).to be_falsey
      end

      it "does not alter the work_package_id of all cost entries" do
        action

        cost_entry.reload
        expect(cost_entry.work_package_id).to eq(work_package.id)
      end
    end

    describe 'w/ "reassign" as action ' \
             "w/ reassigning to a non existing work package" do
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, action: "reassign", reassign_to_id: 0)
      end

      it "returns true" do
        expect(action).to be_falsey
      end

      it "does not alter the work_package_id of all cost entries" do
        action

        cost_entry.reload
        expect(cost_entry.work_package_id).to eq(work_package.id)
      end
    end

    describe 'w/ "reassign" as action ' \
             "w/o providing a reassignment id" do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, action: "reassign") }

      it "returns true" do
        expect(action).to be_falsey
      end

      it "does not alter the work_package_id of all cost entries" do
        action

        cost_entry.reload
        expect(cost_entry.work_package_id).to eq(work_package.id)
      end
    end

    describe "w/ an invalid option" do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, action: "bogus") }

      it "returns false" do
        expect(action).to be_falsey
      end
    end

    describe "w/ nil as invalid option" do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, nil) }

      it "returns false" do
        expect(action).to be_falsey
      end
    end
  end
end
