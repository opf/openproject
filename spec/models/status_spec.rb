#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Status, type: :model do
  let(:stubbed_status) { FactoryBot.build_stubbed(:status) }

  describe 'default status' do
    context 'when default exists' do
      let!(:status) { FactoryBot.create(:default_status) }

      it 'returns that one' do
        expect(Status.default).to eq(status)
        expect(Status.where_default.pluck(:id)).to eq([status.id])
      end
    end
  end

  describe '#is_readonly' do
    let!(:status) { FactoryBot.build(:status, is_readonly: true) }
    context 'when EE enabled', with_ee: %i[readonly_work_packages] do
      it 'is still marked read only' do
        expect(status.is_readonly).to be_truthy
        expect(status.is_readonly?).to be_truthy
      end
    end

    context 'when EE no longer enabled', with_ee: %i[] do
      it 'is still marked read only' do
        expect(status.is_readonly).to be_falsey
        expect(status.is_readonly?).to be_falsey

        # But DB attribute is still correct to keep the state
        # whenever user reactivates
        expect(status.read_attribute(:is_readonly)).to be_truthy
      end
    end
  end

  describe '#cache_key' do
    it 'updates when the updated_at field changes' do
      old_cache_key = stubbed_status.cache_key

      stubbed_status.updated_at = Time.now

      expect(stubbed_status.cache_key)
        .not_to eql old_cache_key
    end
  end

  context '.update_done_ratios' do
    let(:status) { FactoryBot.create(:status, default_done_ratio: 50) }
    let(:work_package) { FactoryBot.create(:work_package, status: status) }

    context 'with Setting.work_package_done_ratio using the field', with_settings: { work_package_done_ratio: 'field' } do
      it 'changes nothing' do
        done_ratio_before = work_package.done_ratio
        Status.update_work_package_done_ratios

        expect(work_package.reload.done_ratio)
          .to eql done_ratio_before
      end
    end

    context 'with Setting.work_package_done_ratio using the status', with_settings: { work_package_done_ratio: 'status' } do
      it "should update all of the issue's done_ratios to match their Issue Status" do
        Status.update_work_package_done_ratios

        expect(work_package.reload.done_ratio)
          .to eql status.default_done_ratio
      end
    end
  end
end
