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

describe WorkPackages::UpdateAncestorsService, type: :model do
  let(:user) { FactoryGirl.create :user }
  let(:estimated_hours) { [nil, nil, nil] }
  let(:done_ratios) { [0, 0, 0] }
  let(:statuses) { %i(open open open) }
  let(:open_status) { FactoryGirl.create :status }
  let(:closed_status) { FactoryGirl.create :closed_status }
  let(:aggregate_done_ratio) { 0.0 }

  context 'for the new ancestor chain' do
    shared_examples 'attributes of parent having children' do
      before do
        children
      end

      it 'updated one work package - the parent' do
        expect(subject.dependent_results.map(&:result))
          .to match_array [parent]
      end

      it 'has the expected aggregate done ratio' do
        expect(subject.dependent_results.first.result.done_ratio)
          .to eq aggregate_done_ratio
      end

      it 'has the expected estimated_hours' do
        expect(subject.dependent_results.first.result.estimated_hours)
          .to eq aggregate_estimated_hours
      end

      it 'is a success' do
        expect(subject)
          .to be_success
      end
    end

    let(:children) do
      (statuses.size - 1).downto(0).map do |i|
        FactoryGirl.create :work_package,
                           parent: parent,
                           status: statuses[i] == :open ? open_status : closed_status,
                           estimated_hours: estimated_hours[i],
                           done_ratio: done_ratios[i]
      end
    end
    let(:parent) { FactoryGirl.create :work_package, status: open_status }

    subject do
      described_class
        .new(user: user,
             work_package: children.first)
        .call(%i(done_ratio estimated_hours))
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
      let(:statuses) { %i(open closed closed) }

      it_behaves_like 'attributes of parent having children' do
        let(:estimated_hours) { [0.0, 2.0, 0.0] }

        let(:aggregate_done_ratio) { 67 } # 66.67 rounded - previous wrong result: 133
        let(:aggregate_estimated_hours) { 2.0 }
      end

      context 'with mixed nil and 0 values for estimated hours' do
        it_behaves_like 'attributes of parent having children' do
          let(:estimated_hours) { [nil, 2.0, 0.0] }

          let(:aggregate_done_ratio) { 67 } # 66.67 rounded - previous wrong result: 100
          let(:aggregate_estimated_hours) { 2.0 }
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
    let(:sibling_status) { open_status }
    let(:sibling_done_ratio) { 50 }
    let(:sibling_estimated_hours) { 7.0 }

    let!(:grandparent) do
      FactoryGirl.create :work_package
    end
    let!(:parent) do
      FactoryGirl.create :work_package,
                         parent: grandparent
    end
    let!(:sibling) do
      FactoryGirl.create :work_package,
                         parent: parent,
                         status: sibling_status,
                         estimated_hours: sibling_estimated_hours,
                         done_ratio: sibling_done_ratio
    end

    let!(:work_package) do
      FactoryGirl.create :work_package,
                         parent: parent
    end

    subject do
      work_package.parent = nil
      work_package.save!

      described_class
        .new(user: user,
             work_package: work_package)
        .call(%i(parent))
    end

    before do
      subject
    end

    it 'is successful' do
      expect(subject)
        .to be_success
    end

    it 'returns the former ancestors in the dependent results' do
      expect(subject.dependent_results.map(&:result))
        .to match_array [parent, grandparent]
    end

    it 'updates the done_ratio of the former parent' do
      expect(parent.reload(select: :done_ratio).done_ratio)
        .to eql sibling_done_ratio
    end

    it 'updates the estimated_hours of the former parent' do
      expect(parent.reload(select: :estimated_hours).estimated_hours)
        .to eql sibling_estimated_hours
    end

    it 'updates the done_ratio of the former grandparent' do
      expect(grandparent.reload(select: :done_ratio).done_ratio)
        .to eql sibling_done_ratio
    end

    it 'updates the estimated_hours of the former grandparent' do
      expect(grandparent.reload(select: :estimated_hours).estimated_hours)
        .to eql sibling_estimated_hours
    end
  end

  context 'for new ancestors' do
    let(:status) { open_status }
    let(:done_ratio) { 50 }
    let(:estimated_hours) { 7.0 }

    let!(:grandparent) do
      FactoryGirl.create :work_package
    end
    let!(:parent) do
      FactoryGirl.create :work_package,
                         parent: grandparent
    end
    let!(:work_package) do
      FactoryGirl.create :work_package,
                         status: status,
                         estimated_hours: estimated_hours,
                         done_ratio: done_ratio
    end

    subject do
      work_package.parent = parent
      work_package.save!
      work_package.parent_id_was

      described_class
        .new(user: user,
             work_package: work_package)
        .call(%i(parent))
    end

    before do
      subject
    end

    it 'is successful' do
      expect(subject)
        .to be_success
    end

    it 'returns the new ancestors in the dependent results' do
      expect(subject.dependent_results.map(&:result))
        .to match_array [parent, grandparent]
    end

    it 'updates the done_ratio of the new parent' do
      expect(parent.reload(select: :done_ratio).done_ratio)
        .to eql done_ratio
    end

    it 'updates the estimated_hours of the new parent' do
      expect(parent.reload(select: :estimated_hours).estimated_hours)
        .to eql estimated_hours
    end

    it 'updates the done_ratio of the new grandparent' do
      expect(grandparent.reload(select: :done_ratio).done_ratio)
        .to eql done_ratio
    end

    it 'updates the estimated_hours of the new grandparent' do
      expect(grandparent.reload(select: :estimated_hours).estimated_hours)
        .to eql estimated_hours
    end
  end
end
