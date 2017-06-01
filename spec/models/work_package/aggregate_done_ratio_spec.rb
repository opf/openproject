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

describe 'WorkPackage#aggregate_done_ratio', type: :model do
  shared_examples 'done ratio of parent having children' do
    let(:statuses) { [:open, :open, :open] }
    let(:done_ratios) { [0, 0, 0] }
    let(:estimated_hours) { [nil, nil, nil] }

    let(:aggregate_done_ratio) { 0.0 }

    let(:open_status) { FactoryGirl.create :status }
    let(:closed_status) { FactoryGirl.create :closed_status }

    let(:parent) { FactoryGirl.create :work_package, status: open_status }

    before do
      (statuses.size - 1).downto(0).each do |i|
        FactoryGirl.create :work_package,
                           parent: parent,
                           status: statuses[i] == :open ? open_status : closed_status,
                           estimated_hours: estimated_hours[i],
                           done_ratio: done_ratios[i]
      end

      parent.reload
    end

    it 'has the expected aggregate done ratio' do
      expect(parent.send(:aggregate_done_ratio)).to eq aggregate_done_ratio
    end
  end

  context 'with no estimated hours and no progress' do
    it_behaves_like 'done ratio of parent having children' do
      let(:statuses) { [:open, :open, :open] }

      let(:aggregate_done_ratio) { 0.0 }
    end
  end

  context 'with 1 out of 3 tasks having estimated hours and 2 out of 3 tasks done' do
    it_behaves_like 'done ratio of parent having children' do
      let(:statuses) { [:open, :closed, :closed] }
      let(:estimated_hours) { [0.0, 2.0, 0.0] }

      let(:aggregate_done_ratio) { 66.67 } # previous wrong result: 133
    end

    context 'with mixed nil and 0 values for estimated hours' do
      it_behaves_like 'done ratio of parent having children' do
        let(:statuses) { [:open, :closed, :closed] }
        let(:estimated_hours) { [nil, 2.0, 0.0] }

        let(:aggregate_done_ratio) { 66.67 } # previous wrong result: 100
      end
    end
  end

  context 'with no estimated hours and 1.5 of the tasks done' do
    it_behaves_like 'done ratio of parent having children' do
      let(:done_ratios) { [0, 50, 100] }

      let(:aggregate_done_ratio) { 50 }
    end
  end

  context 'with esimated hours being 1, 2 and 5' do
    let(:hours) { [1, 2, 5] }

    context 'with the last 2 tasks at 100% progress' do
      it_behaves_like 'done ratio of parent having children' do
        let(:done_ratios) { [0, 100, 100] }
        let(:estimated_hours) { hours }

        let(:aggregate_done_ratio) { 87.5 } # (2 + 5 = 7) / 8 estimated hours done
      end
    end

    context 'with the last 2 tasks closed (therefore at 100%)' do
      it_behaves_like 'done ratio of parent having children' do
        let(:statuses) { [:open, :closed, :closed] }
        let(:estimated_hours) { hours }

        let(:aggregate_done_ratio) { 87.5 } # (2 + 5 = 7) / 8 estimated hours done
      end
    end

    context 'with mixed done ratios, statuses' do
      it_behaves_like 'done ratio of parent having children' do
        let(:done_ratios) { [50, 75, 42] }
        let(:statuses) { [:open, :open, :closed] }
        let(:estimated_hours) { hours }
                                            #  50%       75%        100% (42 ignored)
                                            # (0.5 * 1 + 0.75 * 2 + 1 * 5 [since closed] = 7)
        let(:aggregate_done_ratio) { 87.5 } # (0.5 + 1.5 + 5 = 7) / 8 estimated hours done
      end
    end
  end

  context 'with everything playing together' do
    it_behaves_like 'done ratio of parent having children' do
      let(:statuses) { [:open, :open, :closed, :open] }
      let(:done_ratios) { [0, 0, 0, 50] }
      let(:estimated_hours) { [0.0, 3.0, nil, 7.0] }

      # (0 * 5 + 0 * 3 + 1 * 5 + 0.5 * 7 = 8.5) / 20 est. hours done
      let(:aggregate_done_ratio) { 42.5 }
    end
  end
end
