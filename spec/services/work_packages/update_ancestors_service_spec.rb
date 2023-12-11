#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe WorkPackages::UpdateAncestorsService, type: :model do
  shared_association_default(:author, factory_name: :user) { create(:user) }
  shared_association_default(:project_with_types) { create(:project_with_types) }
  shared_association_default(:priority) { create(:priority) }
  shared_association_default(:open_status, factory_name: :status) { create(:status) }
  shared_let(:closed_status) { create(:closed_status) }
  shared_let(:user) { create(:user) }

  let(:estimated_hours) { [nil, nil, nil] }
  let(:done_ratios) { [0, 0, 0] }
  let(:statuses) { %i(open open open) }
  let(:aggregate_done_ratio) { 0.0 }
  let(:ignore_non_working_days) { [false, false, false] }

  describe 'done_ratio/estimated_hours/remaining_hours propagation' do
    context 'for the new ancestor chain' do
      shared_examples 'attributes of parent having children' do
        before do
          children
        end

        it 'is a success' do
          expect(subject)
          .to be_success
        end

        it 'updated one work package - the parent' do
          expect(subject.dependent_results.map(&:result))
          .to contain_exactly(parent)
        end

        it 'has the expected aggregate done ratio' do
          expect(subject.dependent_results.first.result.done_ratio)
          .to eq aggregate_done_ratio
        end

        it 'has the expected derived estimated_hours' do
          expect(subject.dependent_results.first.result.derived_estimated_hours)
          .to eq aggregate_estimated_hours
        end
      end

      let(:children) do
        (statuses.size - 1).downto(0).map do |i|
          create(:work_package,
                 parent:,
                 status: statuses[i] == :open ? open_status : closed_status,
                 estimated_hours: estimated_hours[i],
                 done_ratio: done_ratios[i],
                 ignore_non_working_days:)
        end
      end

      shared_let(:parent) { create(:work_package, status: open_status) }

      subject do
        # In the call we only use estimated_hours (instead of also adding
        # done_ratio) in order to test that changes in estimated hours
        # trigger a recalculation of done_ration, because estimated hours
        # act as weights in this calculation.
        described_class
          .new(user:,
               work_package: children.first)
          .call(%i(estimated_hours))
      end

      context 'with no estimated hours and no progress' do
        let(:statuses) { %i(open open open) }

        it 'is a success' do
          expect(subject)
          .to be_success
        end

        it 'does not update the parent' do
          expect(subject.dependent_results)
          .to be_empty
        end
      end

      context 'with 1 out of 3 tasks having estimated hours and 2 out of 3 tasks done' do
        let(:statuses) do
          %i(open closed closed)
        end

        it_behaves_like 'attributes of parent having children' do
          let(:estimated_hours) do
            [0.0, 2.0, 0.0]
          end

          # 66.67 rounded - previous wrong result: 133
          let(:aggregate_done_ratio) do
            67
          end
          let(:aggregate_estimated_hours) do
            2.0
          end
        end

        context 'with mixed nil and 0 values for estimated hours' do
          it_behaves_like 'attributes of parent having children' do
            let(:estimated_hours) do
              [nil, 2.0, 0.0]
            end

            # 66.67 rounded - previous wrong result: 100
            let(:aggregate_done_ratio) do
              67
            end
            let(:aggregate_estimated_hours) do
              2.0
            end
          end
        end
      end

      context 'with some values same for done ratio' do
        it_behaves_like 'attributes of parent having children' do
          let(:done_ratios) { [20, 20, 50] }
          let(:estimated_hours) { [nil, nil, nil] }

          let(:aggregate_done_ratio) { 30 }
          let(:aggregate_estimated_hours) { nil }
        end
      end

      context 'with no estimated hours and 1.5 of the tasks done' do
        it_behaves_like 'attributes of parent having children' do
          let(:done_ratios) { [0, 50, 100] }

          let(:aggregate_done_ratio) { 50 }
          let(:aggregate_estimated_hours) { nil }
        end
      end

      context 'with estimated hours being 1, 2 and 5' do
        let(:estimated_hours) { [1, 2, 5] }

        context 'with the last 2 tasks at 100% progress' do
          it_behaves_like 'attributes of parent having children' do
            let(:done_ratios) { [0, 100, 100] }

            # (2 + 5 = 7) / 8 estimated hours done
            let(:aggregate_done_ratio) { 88 } # 87.5 rounded
            let(:aggregate_estimated_hours) { estimated_hours.sum }
          end
        end

        context 'with the last 2 tasks closed (therefore at 100%)' do
          it_behaves_like 'attributes of parent having children' do
            let(:statuses) { %i(open closed closed) }

            # (2 + 5 = 7) / 8 estimated hours done
            let(:aggregate_done_ratio) { 88 } # 87.5 rounded
            let(:aggregate_estimated_hours) { estimated_hours.sum }
          end
        end

        context 'with mixed done ratios, statuses' do
          it_behaves_like 'attributes of parent having children' do
            let(:done_ratios) { [50, 75, 42] }
            let(:statuses) { %i(open open closed) }

            #  50%       75%        100% (42 ignored)
            # (0.5 * 1 + 0.75 * 2 + 1 * 5 [since closed] = 7)
            # (0.5 + 1.5 + 5 = 7) / 8 estimated hours done
            let(:aggregate_done_ratio) { 88 } # 87.5 rounded
            let(:aggregate_estimated_hours) { estimated_hours.sum }
          end
        end
      end

      context 'with everything playing together' do
        it_behaves_like 'attributes of parent having children' do
          let(:statuses) { %i(open open closed open) }
          let(:done_ratios) { [0, 0, 0, 50] }
          let(:estimated_hours) { [0.0, 3.0, nil, 7.0] }

          # (0 * 5 + 0 * 3 + 1 * 5 + 0.5 * 7 = 8.5) / 20 est. hours done
          let(:aggregate_done_ratio) { 43 } # 42.5 rounded
          let(:aggregate_estimated_hours) { 10.0 }
        end
      end
    end

    context 'for the previous ancestors' do
      shared_let(:sibling_status) { open_status }
      shared_let(:sibling_done_ratio) { 50 }
      shared_let(:sibling_estimated_hours) { 7.0 }
      shared_let(:sibling_remaining_hours) { 3.5 }

      shared_let(:grandparent) do
        create(:work_package,
               subject: 'grandparent')
      end
      shared_let(:parent) do
        create(:work_package,
               subject: 'parent',
               parent: grandparent)
      end
      shared_let(:sibling) do
        create(:work_package,
               subject: 'sibling',
               parent:,
               status: sibling_status,
               done_ratio: sibling_done_ratio,
               estimated_hours: sibling_estimated_hours,
               remaining_hours: sibling_remaining_hours)
      end

      shared_let(:work_package) do
        create(:work_package,
               subject: 'subject - loses its parent',
               parent:)
      end

      subject do
        work_package.parent = nil
        work_package.save!

        described_class
          .new(user:,
               work_package:)
          .call(%i(parent))
      end

      it 'is successful' do
        expect(subject)
          .to be_success
      end

      it 'returns the former ancestors in the dependent results' do
        expect(subject.dependent_results.map(&:result))
          .to contain_exactly(parent, grandparent)
      end

      it 'updates the done_ratio, derived_estimated_hours, and derived_remaining_hours of the former parent' do
        expect do
          subject
          parent.reload
        end
          .to change(parent, :done_ratio).to(sibling_done_ratio)
          .and change(parent, :derived_estimated_hours).to(sibling_estimated_hours)
          .and change(parent, :derived_remaining_hours).to(sibling_remaining_hours)
      end

      it 'updates the done_ratio, derived_estimated_hours, and derived_remaining_hours of the former grandparent' do
        expect do
          subject
          grandparent.reload
        end
          .to change(grandparent, :done_ratio).to(sibling_done_ratio)
          .and change(grandparent, :derived_estimated_hours).to(sibling_estimated_hours)
          .and change(grandparent, :derived_remaining_hours).to(sibling_remaining_hours)
      end
    end

    context 'for new ancestors' do
      shared_let(:status) { open_status }
      shared_let(:done_ratio) { 50 }
      shared_let(:estimated_hours) { 7.0 }
      shared_let(:remaining_hours) { 3.5 }

      shared_let(:grandparent) do
        create(:work_package,
               subject: 'grandparent')
      end
      shared_let(:parent) do
        create(:work_package,
               subject: 'parent',
               parent: grandparent)
      end
      shared_let(:work_package) do
        create(:work_package,
               subject: 'subject - gains a new parent and grandparent',
               status:,
               done_ratio:,
               estimated_hours:,
               remaining_hours:)
      end

      shared_examples_for 'updates the attributes within the new hierarchy' do
        it 'is successful' do
          expect(subject)
            .to be_success
        end

        it 'returns the new ancestors in the dependent results' do
          expect(subject.dependent_results.map(&:result))
            .to contain_exactly(parent, grandparent)
        end

        it 'updates the done_ratio, derived_estimated_hours, and derived_remaining_hours of the new parent' do
          expect do
            subject
            parent.reload
          end
            .to change(parent, :done_ratio).to(done_ratio)
            .and change(parent, :derived_estimated_hours).to(estimated_hours)
            .and change(parent, :derived_remaining_hours).to(remaining_hours)
        end

        it 'updates the done_ratio, derived_estimated_hours, and derived_remaining_hours of the new grandparent' do
          expect do
            subject
            grandparent.reload
          end
            .to change(grandparent, :done_ratio).to(done_ratio)
            .and change(grandparent, :derived_estimated_hours).to(estimated_hours)
            .and change(grandparent, :derived_remaining_hours).to(remaining_hours)
        end
      end

      context 'if setting the parent' do
        subject do
          work_package.parent = parent
          work_package.save!

          described_class
            .new(user:,
                 work_package:)
            .call(%i(parent))
        end

        it_behaves_like 'updates the attributes within the new hierarchy'
      end

      context 'if setting the parent_id' do
        subject do
          work_package.parent_id = parent.id
          work_package.save!

          described_class
            .new(user:,
                 work_package:)
            .call(%i(parent_id))
        end

        it_behaves_like 'updates the attributes within the new hierarchy'
      end
    end

    context 'with old and new parent having a common ancestor' do
      shared_let(:status) { open_status }
      shared_let(:done_ratio) { 50 }
      shared_let(:estimated_hours) { 7.0 }
      shared_let(:remaining_hours) { 3.5 }
      shared_let(:new_done_ratio) { 80 }
      shared_let(:new_estimated_hours) { 10.0 }
      shared_let(:new_remaining_hours) { 2 }

      shared_let(:grandparent) do
        create(:work_package,
               subject: 'common grandparent',
               done_ratio: done_ratio / 2, # two children having [done_ratio, 0]
               derived_estimated_hours: estimated_hours,
               derived_remaining_hours: remaining_hours)
      end
      shared_let(:old_parent) do
        create(:work_package,
               subject: 'old parent',
               parent: grandparent,
               done_ratio:,
               derived_estimated_hours: estimated_hours,
               derived_remaining_hours: remaining_hours)
      end
      shared_let(:new_parent) do
        create(:work_package,
               subject: 'new parent',
               parent: grandparent)
      end
      shared_let(:work_package) do
        create(:work_package,
               subject: 'subject - parent changes from old parent to new parent, same grandparent',
               parent: old_parent,
               status:,
               done_ratio:,
               estimated_hours:,
               remaining_hours:)
      end

      subject do
        work_package.parent = new_parent
        # In this test case, done_ratio, derived_estimated_hours, and
        # derived_remaining_hours would not inherently change on grandparent.
        # However, if work_package has siblings then changing its parent could
        #  cause done_ratio, derived_estimated_hours, and/or
        # derived_remaining_hours on grandparent to inherently change. To verify
        # that grandparent can be properly updated in that case without making
        # this test dependent on the implementation details of the calculations,
        # done_ratio, derived_estimated_hours, and derived_remaining_hours are
        # forced to change at the same time as the parent.
        work_package.done_ratio = new_done_ratio
        work_package.estimated_hours = new_estimated_hours
        work_package.remaining_hours = new_remaining_hours
        work_package.save!

        described_class
          .new(user:,
               work_package:)
          .call(%i(parent))
      end

      it 'is successful' do
        expect(subject)
          .to be_success
      end

      it 'returns both the former and new ancestors in the dependent results without duplicates' do
        expect(subject.dependent_results.map(&:result))
          .to contain_exactly(new_parent, grandparent, old_parent)
      end

      it 'updates the done_ratio, derived_estimated_hours, and derived_remaining_hours of the former parent to 0' do
        expect do
          subject
          old_parent.reload
        end
          .to change(old_parent, :done_ratio).to(0)
          .and change(old_parent, :derived_estimated_hours).to(nil)
          .and change(old_parent, :derived_remaining_hours).to(nil)
      end

      it 'updates the done_ratio, derived_estimated_hours, and derived_remaining_hours of the new parent' do
        expect do
          subject
          new_parent.reload
        end
          .to change(new_parent, :done_ratio).to(new_done_ratio)
          .and change(new_parent, :derived_estimated_hours).to(new_estimated_hours)
          .and change(new_parent, :derived_remaining_hours).to(new_remaining_hours)
      end

      it 'updates the done_ratio, derived_estimated_hours, and derived_remaining_hours of the grandparent' do
        expect do
          subject
          grandparent.reload
        end
          .to change(grandparent, :done_ratio).to(new_done_ratio / 2) # two children having [new_done_ratio, 0] now
          .and change(grandparent, :derived_estimated_hours).to(new_estimated_hours)
          .and change(grandparent, :derived_remaining_hours).to(new_remaining_hours)
      end
    end
  end

  describe 'remaining_hours propagation' do
    shared_let(:parent) { create(:work_package, status: open_status) }

    context 'for the new ancestors chain' do
      shared_context 'when called with children' do |children_remaining_hours:|
        let(:children) do
          (children_remaining_hours.size - 1).downto(0).map do |i|
            create(:work_package,
                   parent:,
                   status: open_status,
                   remaining_hours: children_remaining_hours[i])
          end
        end
        subject(:call_result) do
          described_class.new(user:, work_package: children.first)
                         .call(%i(remaining_hours))
        end
      end

      shared_examples 'derived remaining hours' do |children_remaining_hours:, expected_derived_remaining_hours:|
        context "for #{children_remaining_hours.count} children with remaining hours being #{children_remaining_hours.inspect}" do
          include_context('when called with children', children_remaining_hours:)

          it "sets parent derived remaining hours to #{expected_derived_remaining_hours}", :aggregate_failures do
            expect(call_result).to be_success
            expect(call_result.dependent_results.map(&:result))
              .to contain_exactly(parent)
            expect(call_result.dependent_results.first.result.derived_remaining_hours)
              .to eq(expected_derived_remaining_hours)
          end
        end
      end

      include_examples 'derived remaining hours',
                       children_remaining_hours: [0.0, 2.0, nil],
                       expected_derived_remaining_hours: 2.0

      include_examples 'derived remaining hours',
                       children_remaining_hours: [1, 2, 5, 42],
                       expected_derived_remaining_hours: 50

      context 'with no remaining hours' do
        include_context('when called with children', children_remaining_hours: [nil, nil, nil])

        it 'does not update the parent derived remaining hours' do
          expect(call_result).to be_success
          expect(call_result.dependent_results).to be_empty
        end
      end
    end
  end

  describe 'ignore_non_working_days propagation' do
    shared_let(:grandgrandparent) do
      create(:work_package,
             subject: 'grandgrandparent')
    end
    shared_let(:grandparent) do
      create(:work_package,
             subject: 'grandparent',
             parent: grandgrandparent)
    end
    shared_let(:parent) do
      create(:work_package,
             subject: 'parent',
             parent: grandparent)
    end
    shared_let(:sibling) do
      create(:work_package,
             subject: 'sibling',
             parent:)
    end
    shared_let(:work_package) do
      create(:work_package)
    end

    subject do
      work_package.parent = new_parent
      work_package.save!

      described_class
        .new(user:,
             work_package:)
        .call(%i(parent))
    end

    let(:new_parent) { parent }

    context 'for the previous ancestors (parent removed)' do
      let(:new_parent) { nil }

      before do
        work_package.parent = parent
        work_package.save

        [grandgrandparent, grandparent, parent, work_package].each do |wp|
          wp.update_column(:ignore_non_working_days, true)
        end

        [sibling].each do |wp|
          wp.update_column(:ignore_non_working_days, false)
        end
      end

      it 'is successful' do
        expect(subject)
          .to be_success
      end

      it 'returns the former ancestors in the dependent results' do
        expect(subject.dependent_results.map(&:result))
          .to contain_exactly(parent, grandparent, grandgrandparent)
      end

      it 'sets the ignore_non_working_days property of the former ancestor chain to the value of the
          only remaining child (former sibling)' do
        subject

        expect(parent.reload.ignore_non_working_days)
          .to be_falsey

        expect(grandparent.reload.ignore_non_working_days)
          .to be_falsey

        expect(grandgrandparent.reload.ignore_non_working_days)
          .to be_falsey

        expect(sibling.reload.ignore_non_working_days)
          .to be_falsey
      end
    end

    context 'for the new ancestors where the grandparent is on manual scheduling' do
      before do
        [grandgrandparent, work_package].each do |wp|
          wp.update_column(:ignore_non_working_days, true)
        end

        [grandparent, parent, sibling].each do |wp|
          wp.update_column(:ignore_non_working_days, false)
        end

        [grandparent].each do |wp|
          wp.update_column(:schedule_manually, true)
        end
      end

      it 'is successful' do
        expect(subject)
          .to be_success
      end

      it 'returns the former ancestors in the dependent results' do
        expect(subject.dependent_results.map(&:result))
          .to contain_exactly(parent)
      end

      it 'sets the ignore_non_working_days property of the new ancestors' do
        subject

        expect(parent.reload.ignore_non_working_days)
          .to be_truthy

        expect(grandparent.reload.ignore_non_working_days)
          .to be_falsey

        expect(grandgrandparent.reload.ignore_non_working_days)
          .to be_truthy

        expect(sibling.reload.ignore_non_working_days)
          .to be_falsey
      end
    end

    context 'for the new ancestors where the parent is on manual scheduling' do
      before do
        [grandgrandparent, grandparent, work_package].each do |wp|
          wp.update_column(:ignore_non_working_days, true)
        end

        [parent, sibling].each do |wp|
          wp.update_column(:ignore_non_working_days, false)
        end

        [parent].each do |wp|
          wp.update_column(:schedule_manually, true)
        end
      end

      it 'is successful' do
        expect(subject)
          .to be_success
      end

      it 'returns the former ancestors in the dependent results' do
        expect(subject.dependent_results.map(&:result))
          .to be_empty
      end

      it 'sets the ignore_non_working_days property of the new ancestors' do
        subject

        expect(parent.reload.ignore_non_working_days)
          .to be_falsey

        expect(grandparent.reload.ignore_non_working_days)
          .to be_truthy

        expect(grandgrandparent.reload.ignore_non_working_days)
          .to be_truthy

        expect(sibling.reload.ignore_non_working_days)
          .to be_falsey
      end
    end
  end
end
