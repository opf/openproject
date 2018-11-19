#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

  describe '.new_statuses_allowed' do
    let(:role) { FactoryBot.create(:role) }
    let(:type) { FactoryBot.create(:type) }
    let(:statuses) { (1..4).map { |_i| FactoryBot.create(:status) } }
    let(:status) { statuses[0] }
    let(:workflow_a) do
      FactoryBot.create(:workflow, role_id: role.id,
                                    type_id: type.id,
                                    old_status_id: statuses[0].id,
                                    new_status_id: statuses[1].id,
                                    author: false,
                                    assignee: false)
    end
    let(:workflow_b) do
      FactoryBot.create(:workflow, role_id: role.id,
                                    type_id: type.id,
                                    old_status_id: statuses[0].id,
                                    new_status_id: statuses[2].id,
                                    author: true,
                                    assignee: false)
    end
    let(:workflow_c) do
      FactoryBot.create(:workflow, role_id: role.id,
                                    type_id: type.id,
                                    old_status_id: statuses[0].id,
                                    new_status_id: statuses[3].id,
                                    author: false,
                                    assignee: true)
    end
    let(:workflows) { [workflow_a, workflow_b, workflow_c] }

    before do
      workflows
    end

    it 'should respect workflows w/o author and w/o assignee' do
      expect(Status.new_statuses_allowed(status, [role], type, false, false))
        .to match_array([statuses[1]])
    end

    it 'should respect workflows w/ author and w/o assignee' do
      expect(Status.new_statuses_allowed(status, [role], type, true, false))
        .to match_array([statuses[1], statuses[2]])
    end

    it 'should respect workflows w/o author and w/ assignee' do
      expect(Status.new_statuses_allowed(status, [role], type, false, true))
        .to match_array([statuses[1], statuses[3]])
    end

    it 'should respect workflows w/ author and w/ assignee' do
      expect(Status.new_statuses_allowed(status, [role], type, true, true))
        .to match_array([statuses[1], statuses[2], statuses[3]])
    end
  end

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
end
