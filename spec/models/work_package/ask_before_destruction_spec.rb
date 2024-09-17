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
    create(:member,
           principal: user,
           roles: [role])
  end
  let(:member2) do
    create(:member,
           principal: user,
           roles: [role2],
           project: work_package2.project)
  end
  let(:status) { create(:status) }
  let(:priority) { create(:priority) }
  let(:time_entry_hours) { 10 }
  let(:time_entry) do
    create(:time_entry,
           hours: time_entry_hours,
           work_package:,
           project: work_package.project)
  end
  let(:time_entry2) do
    create(:time_entry,
           work_package: work_package2,
           project: work_package2.project)
  end

  describe "#cleanup_action_required_before_destructing?" do
    describe "with the work package having a time entry" do
      before do
        work_package
        time_entry
      end

      it "is true" do
        expect(WorkPackage.cleanup_action_required_before_destructing?(work_package)).to be_truthy
      end
    end

    describe "with two work packages having a time entry" do
      before do
        work_package
        time_entry
        time_entry2
      end

      it "is true" do
        expect(WorkPackage.cleanup_action_required_before_destructing?([work_package, work_package2])).to be_truthy
      end
    end

    describe "without the work package having a time entry" do
      before do
        work_package
      end

      it "is false" do
        expect(WorkPackage.cleanup_action_required_before_destructing?(work_package)).to be_falsey
      end
    end
  end

  describe "#associated_classes_to_address_before_destructing?" do
    describe "with the work package having a time entry" do
      before do
        work_package
        time_entry
      end

      it "is have 'TimeEntry' as class to address" do
        expect(WorkPackage.associated_classes_to_address_before_destruction_of(work_package)).to eq([TimeEntry])
      end
    end

    describe "without the work package having a time entry" do
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
      work_package

      time_entry
    end

    describe "without a cleanup being necessary" do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user, action: "reassign") }

      before do
        time_entry.destroy
      end

      it "returns true" do
        expect(action).to be_truthy
      end
    end

    describe 'with "destroy" as action' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user, action: "destroy") }

      it "returns true" do
        expect(action).to be_truthy
      end

      it "does not touch the time_entry" do
        action

        time_entry.reload
        expect(time_entry.work_package_id).to eq(work_package.id)
      end
    end

    describe "without an action" do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user) }

      it "returns true" do
        expect(action).to be_truthy
      end

      it "does not touch the time_entry" do
        action

        time_entry.reload
        expect(time_entry.work_package_id).to eq(work_package.id)
      end
    end

    describe 'with "nullify" as action' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user, action: "nullify") }

      it "returns true" do
        expect(action).to be_truthy
      end

      it "sets the work_package_id of all time entries to nil" do
        action

        time_entry.reload
        expect(time_entry.work_package_id).to be_nil
      end
    end

    describe 'with "reassign" as action ' \
             "with reassigning to a valid work_package" do
      context "with a single work package" do
        let(:action) do
          WorkPackage.cleanup_associated_before_destructing_if_required(work_package,
                                                                        user,
                                                                        action: "reassign",
                                                                        reassign_to_id: work_package2.id)
        end

        before do
          work_package2
          role2.add_permission! :edit_time_entries
          member2
        end

        it "returns true" do
          expect(action).to be_truthy
        end

        it "sets the work_package_id of all time entries to the new work package" do
          action

          time_entry.reload
          expect(time_entry.work_package_id).to eq(work_package2.id)
        end

        it "sets the project_id of all time entries to the new work package's project" do
          action

          time_entry.reload
          expect(time_entry.project_id).to eq(work_package2.project_id)
        end
      end

      context "with a collection of work packages" do
        let(:action) do
          WorkPackage.cleanup_associated_before_destructing_if_required([work_package],
                                                                        user,
                                                                        action: "reassign",
                                                                        reassign_to_id: work_package2.id)
        end

        before do
          work_package2
          role2.add_permission! :edit_time_entries
          role2.save!
          member2.save!
        end

        it "returns true" do
          expect(action).to be_truthy
        end

        it "sets the work_package_id of all time entries to the new work package" do
          action

          time_entry.reload
          expect(time_entry.work_package_id).to eq(work_package2.id)
        end

        it "sets the project_id of all time entries to the new work package's project" do
          action

          time_entry.reload
          expect(time_entry.project_id).to eq(work_package2.project_id)
        end
      end
    end

    describe 'with "reassign" as action ' \
             "with reassigning to a work_package the user is not allowed to see" do
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required([work_package],
                                                                      user,
                                                                      action: "reassign",
                                                                      reassign_to_id: work_package2.id)
      end

      before do
        work_package2
      end

      it "returns true" do
        expect(action).to be_falsey
      end

      it "does not alter the work_package_id of all time entries" do
        action

        time_entry.reload
        expect(time_entry.work_package_id).to eq(work_package.id)
      end
    end

    describe 'with "reassign" as action ' \
             "with reassigning to a non existing work package" do
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required([work_package],
                                                                      user,
                                                                      action: "reassign",
                                                                      reassign_to_id: 0)
      end

      it "returns true" do
        expect(action).to be_falsey
      end

      it "does not alter the work_package_id of all time entries" do
        action

        time_entry.reload
        expect(time_entry.work_package_id).to eq(work_package.id)
      end

      it "sets an error on work packages" do
        action

        expect(work_package.errors[:base])
          .to eq([I18n.t(:"activerecord.errors.models.work_package.is_not_a_valid_target_for_time_entries", id: 0)])
      end
    end

    describe 'with "reassign" as action ' \
             "without providing a reassignment id" do
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required([work_package],
                                                                      user,
                                                                      action: "reassign")
      end

      it "returns true" do
        expect(action).to be_falsey
      end

      it "does not alter the work_package_id of all time entries" do
        action

        time_entry.reload
        expect(time_entry.work_package_id).to eq(work_package.id)
      end

      it "sets an error on work packages" do
        action

        expect(work_package.errors[:base])
          .to eq([I18n.t(:"activerecord.errors.models.work_package.is_not_a_valid_target_for_time_entries", id: nil)])
      end
    end

    describe "with an invalid option" do
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required([work_package],
                                                                      user,
                                                                      action: "bogus")
      end

      it "returns false" do
        expect(action).to be_falsey
      end
    end

    describe "with nil as invalid option" do
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required([work_package],
                                                                      user,
                                                                      nil)
      end

      it "returns false" do
        expect(action).to be_falsey
      end
    end
  end
end
