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

describe Api::Experimental::WorkPackagesController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:type) { FactoryGirl.create(:type_standard) }
  let(:project_1) {
    FactoryGirl.create(:project,
                       types: [type])
  }
  let(:project_2) {
    FactoryGirl.create(:project,
                       types: [type],
                       is_public: false)
  }
  let(:role) do
    FactoryGirl.create(:role, permissions: [:view_work_packages,
                                            :add_work_packages,
                                            :edit_work_packages,
                                            :move_work_packages,
                                            :delete_work_packages,
                                            :log_time])
  end
  let(:status_1) { FactoryGirl.create(:status) }
  let(:work_package_1) {
    FactoryGirl.create(:work_package,
                       author: user,
                       type: type,
                       status: status_1,
                       project: project_1)
  }
  let(:work_package_2) {
    FactoryGirl.create(:work_package,
                       author: user,
                       type: type,
                       status: status_1,
                       project: project_1)
  }
  let(:work_package_3) {
    FactoryGirl.create(:work_package,
                       author: user,
                       type: type,
                       status: status_1,
                       project: project_2)
  }

  let(:current_user) do
    FactoryGirl.create(:user, member_in_project: project_1,
                              member_through_role: role)
  end

  let(:query_1) do
    FactoryGirl.create(:query,
                       project: project_1,
                       user: current_user)
  end

  before do
    allow(User).to receive(:current).and_return(current_user)
  end

  describe '#index' do
    context 'with no work packages available' do
      it 'renders the index template' do
        get 'index', format: 'json'
        expect(response).to render_template('api/experimental/work_packages/index')
      end

      it 'assigns a query which has the default filter arguments set' do
        allow(Query).to receive(:new).and_call_original
        expected_query = Query.new name: '_'
        expect(Query)
          .to receive(:new)
          .with(anything, initialize_with_default_filter: true)
          .and_return(expected_query)

        get 'index', format: 'json'

        expect(assigns(:query)).to eq expected_query
      end

      %w(groupBy c fields f sort isPublic name displaySums).each do |filter_param|
        it "assigns a query which does not have the default filter arguments set if the #{filter_param} argument is provided" do
          allow(Query).to receive(:new).and_call_original
          expected_query = Query.new
          expect(Query).to receive(:new).with(anything, initialize_with_default_filter: false)
            .and_return(expected_query)

          get 'index', format: 'json', filter_param => double('anything', to_i: 1).as_null_object

          expect(assigns(:query)).to eql expected_query
        end
      end
    end

    context 'without the necessary permissions' do
      let(:role) { FactoryGirl.create(:role, permissions: []) }

      it 'should return 403 for the global action' do
        get 'index', format: 'json'

        expect(response.response_code).to eql(403)
      end

      it 'should return 403 for the project based action' do
        get 'index', format: 'json', project_id: project_1.id

        expect(response.response_code).to eql(403)
      end

      context 'viewing another persions private query' do
        let(:other_user) do
          FactoryGirl.create(:user, member_in_project: project_1,
                                    member_through_role: role)
        end

        let(:role) do
          FactoryGirl.create(:role, permissions: [:view_work_packages])
        end

        it 'is visible by the owner' do
          get 'index', format: 'json', queryId: query_1.id, project_id: project_1.id
          expect(response.response_code).to eql(200)
        end

        it 'is not visible by another user' do
          allow(User).to receive(:current).and_return(other_user)

          get 'index', format: 'json', queryId: query_1.id, project_id: project_1.id
          expect(response.response_code).to eql(404)
        end
      end
    end
  end
end
