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
