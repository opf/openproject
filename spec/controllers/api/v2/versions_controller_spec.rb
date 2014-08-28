#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe Api::V2::VersionsController, type: :controller do

  let(:admin_user) { FactoryGirl.create(:admin) }

  describe '#index' do
    let(:version) { FactoryGirl.create(:version) }

    context 'unauthorized access' do
      let(:project) { FactoryGirl.create(:project) }

      before { get :index, project_id: project.id, format: :xml }

      it { expect(response.status).to eq(401) }
    end

    context 'with access' do
      let(:project) { FactoryGirl.create(:project) }

      before do
        allow(User).to receive(:current).and_return admin_user
      end

      before { get :index, project_id: project.id, format: :xml }

      it { expect(response.status).to eq(200) }
      xit 'should render something'
    end
  end

  describe '#show' do
    let(:project) { FactoryGirl.create(:project) }
    let(:version) { FactoryGirl.create(:version, name: 'Sprint 45', project: project) }

    before do
      allow(User).to receive(:current).and_return admin_user
    end

    context 'with access' do
      it 'that does not exist should raise an error' do
        get :show, id: '0', project_id: project.id, format: :json
        expect(response.response_code).to eq(404)
      end

      it 'that exists should return the proper version' do
        get :show, id: version.id, project_id: project.id, format: :json
        expect(assigns(:version)).to eql version
      end
    end
  end
end
