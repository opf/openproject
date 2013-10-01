#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackage do
  describe :relation do
    let(:closed_state) { FactoryGirl.create(:status,
                                            is_closed: true) }

    describe :duplicate do
      let(:original) { FactoryGirl.create(:work_package) }
      let(:dup_1) { FactoryGirl.create(:work_package,
                                       project: original.project) }
      let(:relation_org_dup_1) { FactoryGirl.create(:relation,
                                                    from: dup_1,
                                                    to: original,
                                                    relation_type: Relation::TYPE_DUPLICATES) }

      context "closes duplicates" do
        let(:user) { FactoryGirl.create(:user) }
        let(:dup_2) { FactoryGirl.create(:work_package,
                                         project: original.project) }
        let(:relation_dup_1_dup_2) { FactoryGirl.create(:relation,
                                                        from: dup_2,
                                                        to: dup_1,
                                                        relation_type: Relation::TYPE_DUPLICATES) }
        # circular dependency
        let(:relation_dup_2_org) { FactoryGirl.create(:relation,
                                                      from: dup_2,
                                                      to: original,
                                                      relation_type: Relation::TYPE_DUPLICATES) }

        before do
          User.stub(:current).and_return user

          relation_org_dup_1
          relation_dup_1_dup_2
          relation_dup_2_org

          original.status = closed_state
          original.save!

          dup_1.reload
          dup_2.reload
        end

        it "only duplicates are closed" do
          dup_1.closed?.should be_true
          dup_2.closed?.should be_true
        end
      end

      context "duplicated is not closed" do
        before do
          relation_org_dup_1

          dup_1.status = closed_state
          dup_1.save!

          original.reload
        end

        subject { original.closed? }

        it { should be_false }
      end
    end

    describe :blocks do
      let(:user) { FactoryGirl.create(:user) }
      let(:role) { FactoryGirl.create(:role) }
      let(:type) { FactoryGirl.create(:type) }
      let(:project) { FactoryGirl.create(:project,
                                         types: [type]) }
      let(:status) { FactoryGirl.create(:status) }
      let(:blocks) { FactoryGirl.create(:work_package,
                                        project: project,
                                        status: status) }
      let(:blocked) { FactoryGirl.create(:work_package,
                                         project: project,
                                         type: blocks.type,
                                         status: status) }
      let(:relation_blocks) { FactoryGirl.create(:relation,
                                                 from: blocks,
                                                 to: blocked,
                                                 relation_type: Relation::TYPE_BLOCKS) }

      before { relation_blocks }

      describe :blocked? do
        context "blocked work package" do
          subject { blocked.blocked? }

          it { should be_true }
        end

        context "blocking work package" do
          subject { blocks.blocked? }

          it { should be_false }
        end
      end

      describe "closed state" do
        let(:project_member) { FactoryGirl.create(:member,
                                                  project: project,
                                                  principal: user,
                                                  roles: [role]) }
        let(:workflow_1) { FactoryGirl.create(:workflow,
                                              role: role,
                                              old_status: status,
                                              new_status: status) }
        let(:workflow_2) { FactoryGirl.create(:workflow,
                                              role: role,
                                              old_status: status,
                                              new_status: closed_state) }

        shared_examples_for "work package with status transitions" do
          subject { work_package.new_statuses_allowed_to(user) }

          it { should_not be_empty }
        end

        shared_context "allowed status transitions" do
          subject { work_package.new_statuses_allowed_to(user).select {|s| s.is_closed? } }
        end

        before do
          project_member

          type.workflows << workflow_1
          type.workflows << workflow_2
        end

        context "blocked work package" do
          let(:work_package) { blocked }

          it_behaves_like "work package with status transitions"

          describe "deny closed state" do
            include_context "allowed status transitions"

            it { should be_empty }
          end
        end

        context "blocking work package" do
          let(:work_package) { blocks }

          it_behaves_like "work package with status transitions"

          describe "allow closed state" do
            include_context "allowed status transitions"

            it { should_not be_empty }
          end
        end
      end
    end

    describe :precedes do
      let(:start_date) { Date.today }
      let(:due_date) { Date.today + 2 }
      let(:preceding) { FactoryGirl.create(:work_package,
                                           start_date: start_date,
                                           due_date: due_date) }
      let(:following) { FactoryGirl.create(:work_package,
                                           project: preceding.project,
                                           start_date: start_date,
                                           due_date: due_date) }
      let(:relation_precedes) { FactoryGirl.create(:relation,
                                                   from: preceding,
                                                   to: following,
                                                   relation_type: Relation::TYPE_PRECEDES) }

      shared_examples_for "following start date" do
        subject { following.reload.start_date }

        it { should eq(preceding.due_date + 1) }
      end

      before { relation_precedes }

      it_behaves_like "following start date"

      describe "preceding end date change" do
        before do
          preceding.due_date = Date.today + 5
          preceding.save!
        end

        it_behaves_like "following start date"
      end
    end

    describe :all_dependant_packages do
      let(:work_package_1) { FactoryGirl.create(:work_package) }
      let(:work_package_2) { FactoryGirl.create(:work_package,
                                                project: work_package_1.project) }
      let(:work_package_3) { FactoryGirl.create(:work_package,
                                                project: work_package_1.project) }
      let(:work_package_4) { FactoryGirl.create(:work_package,
                                                project: work_package_1.project) }

      let(:relation_1) { FactoryGirl.create(:relation,
                                            from: work_package_1,
                                            to: work_package_2,
                                            relation_type: Relation::TYPE_PRECEDES) }
      let(:relation_2) { FactoryGirl.create(:relation,
                                            from: work_package_2,
                                            to: work_package_3,
                                            relation_type: Relation::TYPE_PRECEDES) }

      shared_examples_for "all dependant work packages visible" do
        subject { work_package_1.all_dependent_packages.collect(&:id) }

        it { should =~ expected_ids }
      end

      before do
        relation_1
        relation_2
      end

      context "w/o circular dependency" do
        let(:expected_ids) { [work_package_2.id,
                              work_package_3.id,
                              work_package_4.id] }

        let(:relation_3) { FactoryGirl.create(:relation,
                                              from: work_package_3,
                                              to: work_package_4,
                                              relation_type: Relation::TYPE_PRECEDES) }
        before { relation_3 }

        it_behaves_like "all dependant work packages visible"
      end

      context "with circular dependency" do
        let(:expected_ids) { [work_package_2.id,
                              work_package_3.id] }

        let(:relation_3) { FactoryGirl.build(:relation,
                                             from: work_package_3,
                                             to: work_package_1,
                                             relation_type: Relation::TYPE_PRECEDES) }

        before { relation_3.save(validate: false) }

        it_behaves_like "all dependant work packages visible"
      end

      context "with multiple circular dependency" do
        let(:expected_ids) { [work_package_2.id,
                              work_package_3.id,
                              work_package_4.id] }

        let(:relation_3) { FactoryGirl.create(:relation,
                                              from: work_package_3,
                                              to: work_package_4,
                                              relation_type: Relation::TYPE_PRECEDES) }
        let(:relation_4) { FactoryGirl.build(:relation,
                                             from: work_package_3,
                                             to: work_package_1,
                                             relation_type: Relation::TYPE_PRECEDES) }
        let(:relation_5) { FactoryGirl.build(:relation,
                                             from: work_package_4,
                                             to: work_package_2,
                                             relation_type: Relation::TYPE_PRECEDES) }

        before do
          relation_3.save(validate: false)
          relation_4.save(validate: false)
          relation_5.save(validate: false)
        end

        it_behaves_like "all dependant work packages visible"
      end
    end
  end
end
