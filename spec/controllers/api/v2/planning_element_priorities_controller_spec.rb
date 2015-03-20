#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::V2::PlanningElementPrioritiesController, type: :controller do
  let(:current_user) { FactoryGirl.create(:admin) }

  before { allow(User).to receive(:current).and_return current_user }

  describe '#index' do
    shared_examples_for 'valid work package priority index request' do
      it { expect(response).to be_success }

      it { expect(response).to render_template('api/v2/planning_element_priorities/index', format: ['api']) }
    end

    describe 'w/o priorities' do
      before { get :index, format: :xml }

      it { expect(assigns(:priorities)).to be_empty }

      it_behaves_like 'valid work package priority index request'
    end

    describe 'w/o priorities' do
      let!(:priority_0) { FactoryGirl.create(:priority) }
      let!(:priority_1) {
        FactoryGirl.create(:priority,
                           position: 1)
      }
      let!(:priority_2) {
        FactoryGirl.create(:priority,
                           position: 2,
                           is_default: true)
      }

      before { get :index, format: :xml }

      it { expect(assigns(:priorities)).not_to be_empty }

      it { expect(assigns(:priorities).count).to eq(3) }

      it_behaves_like 'valid work package priority index request'
    end
  end
end
