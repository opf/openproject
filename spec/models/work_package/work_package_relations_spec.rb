#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe WorkPackage, type: :model do
  describe '#relation' do
    let(:closed_state) do
      FactoryGirl.create(:status,
                         is_closed: true)
    end

    describe '#duplicate' do
      let(:original) { FactoryGirl.create(:work_package) }
      let(:dup_1) do
        FactoryGirl.create(:work_package,
                           project: original.project,
                           type: original.type,
                           status: original.status)
      end
      let(:relation_org_dup_1) do
        FactoryGirl.create(:relation,
                           from: dup_1,
                           to: original,
                           relation_type: Relation::TYPE_DUPLICATES)
      end
      let(:workflow) do
        FactoryGirl.create(:workflow,
                           old_status: original.status,
                           new_status: closed_state,
                           type_id: original.type_id)
      end
      let(:user) { FactoryGirl.create(:user) }

      before do
        allow(User).to receive(:current).and_return user

        original.project.add_member!(user, workflow.role)
      end

      context 'closes duplicates' do
        let(:dup_2) do
          FactoryGirl.create(:work_package,
                             project: original.project,
                             type: original.type,
                             status: original.status)
        end
        let(:relation_dup_1_dup_2) do
          FactoryGirl.create(:relation,
                             from: dup_2,
                             to: dup_1,
                             relation_type: Relation::TYPE_DUPLICATES)
        end
        # circular dependency
        let(:relation_dup_2_org) do
          FactoryGirl.create(:relation,
                             from: dup_2,
                             to: original,
                             relation_type: Relation::TYPE_DUPLICATES)
        end

        before do
          relation_org_dup_1
          relation_dup_1_dup_2
          relation_dup_2_org

          original.status = closed_state
          original.save!

          dup_1.reload
          dup_2.reload
        end

        it 'only duplicates are closed' do
          expect(dup_1.closed?).to be_truthy
          expect(dup_2.closed?).to be_truthy
        end
      end

      context 'duplicated is not closed' do
        before do
          relation_org_dup_1

          dup_1.status = closed_state
          dup_1.save!

          original.reload
        end

        subject { original.closed? }

        it { is_expected.to be_falsey }
      end
    end

    describe '#blocks' do
      let(:user) { FactoryGirl.create(:user) }
      let(:role) { FactoryGirl.create(:role) }
      let(:type) { FactoryGirl.create(:type) }
      let(:project) do
        FactoryGirl.create(:project,
                           types: [type])
      end
      let(:status) { FactoryGirl.create(:status) }
      let(:blocks) do
        FactoryGirl.create(:work_package,
                           project: project,
                           status: status)
      end
      let(:blocked) do
        FactoryGirl.create(:work_package,
                           project: project,
                           type: blocks.type,
                           status: status)
      end
      let(:relation_blocks) do
        FactoryGirl.create(:relation,
                           from: blocks,
                           to: blocked,
                           relation_type: Relation::TYPE_BLOCKS)
      end

      before do
        relation_blocks
      end

      describe '#blocked?' do
        context 'blocked work package' do
          subject { blocked.blocked? }

          it { is_expected.to be_truthy }
        end

        context 'blocking work package' do
          subject { blocks.blocked? }

          it { is_expected.to be_falsey }
        end
      end

      describe 'closed state' do
        let(:project_member) do
          FactoryGirl.create(:member,
                             project: project,
                             principal: user,
                             roles: [role])
        end
        let(:workflow_1) do
          FactoryGirl.create(:workflow,
                             role: role,
                             old_status: status,
                             new_status: status)
        end
        let(:workflow_2) do
          FactoryGirl.create(:workflow,
                             role: role,
                             old_status: status,
                             new_status: closed_state)
        end

        shared_examples_for 'work package with status transitions' do
          subject { work_package.new_statuses_allowed_to(user) }

          it { is_expected.not_to be_empty }
        end

        shared_context 'allowed status transitions' do
          subject { work_package.new_statuses_allowed_to(user).select(&:is_closed?) }
        end

        before do
          project_member

          type.workflows << workflow_1
          type.workflows << workflow_2
        end

        context 'blocked work package' do
          let(:work_package) { blocked }

          it_behaves_like 'work package with status transitions'

          describe 'deny closed state' do
            include_context 'allowed status transitions'

            it { is_expected.to be_empty }
          end
        end

        context 'blocking work package' do
          let(:work_package) { blocks }

          it_behaves_like 'work package with status transitions'

          describe 'allow closed state' do
            include_context 'allowed status transitions'

            it { is_expected.not_to be_empty }
          end
        end
      end
    end

    describe '#soonest_start' do
      let(:work_package_1) { FactoryGirl.create(:work_package) }
      let(:work_package_2) do
        FactoryGirl.create(:work_package,
                           project: work_package_1.project)
      end
      let!(:work_package_2_1) do
        FactoryGirl.create(:work_package,
                           parent: work_package_2,
                           project: work_package_1.project)
      end
      let!(:relation_1) do
        FactoryGirl.create(:relation,
                           from: work_package_1,
                           to: work_package_2,
                           relation_type: Relation::TYPE_PRECEDES)
      end

      context 'start date exists in related work packages' do
        before do
          work_package_1.due_date = Date.today
          work_package_1.save!
        end

        it { expect(work_package_2_1.soonest_start).to eq(work_package_1.due_date + 1) }
      end

      context 'no start date exists in related work packages' do
        it { expect(work_package_2_1.soonest_start).to be_nil }
      end
    end
  end
end
