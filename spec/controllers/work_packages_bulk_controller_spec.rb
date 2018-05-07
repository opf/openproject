#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'spec_helper'

describe WorkPackages::BulkController, type: :controller do
  let(:project) { FactoryBot.create(:project_with_types) }
  let(:controller_role) { FactoryBot.build(:role, permissions: [:view_work_packages, :edit_work_packages]) }
  let(:user) { FactoryBot.create :user, member_in_project: project, member_through_role: controller_role }
  let(:cost_object) { FactoryBot.create :cost_object, project: project }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }

  before do
    allow(User).to receive(:current).and_return user
  end

  describe '#update' do
    context 'when a cost report is assigned' do
      before do
        put :update, params: { ids: [work_package.id],
                               work_package: { cost_object_id: cost_object.id } }
      end

      subject { work_package.reload.cost_object.try :id }

      it { is_expected.to eq(cost_object.id) }
    end
  end
end
