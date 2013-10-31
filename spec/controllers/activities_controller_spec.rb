#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

require 'spec_helper'

describe ActivitiesController do
  before :each do
    @controller.stub(:set_localization)

    admin = FactoryGirl.create(:admin)
    User.stub(:current).and_return admin

    @params = {}
  end

  describe 'index' do
    describe 'with activated activity module' do
      before do
        @project = FactoryGirl.create(:project, :enabled_module_names => %w[activity wiki])
        @params[:project_id] = @project.id
      end

      it 'renders activity' do
        get 'index', @params
        response.should be_success
        response.should render_template 'index'
      end
    end

    describe 'without activated activity module' do
      before do
        @project = FactoryGirl.create(:project, :enabled_module_names => %w[wiki])
        @params[:project_id] = @project.id
      end

      it 'renders 403' do
        get 'index', @params
        response.status.should == 403
        response.should render_template 'common/error'
      end
    end

    describe :atom_feed do
      let(:user) { FactoryGirl.create(:user) }
      let(:project) { FactoryGirl.create(:project) }
      let!(:wp_1) { FactoryGirl.create(:work_package,
                                       project: project,
                                       author: user) }
      let!(:wp_2) { FactoryGirl.create(:work_package,
                                       project: project,
                                       author: user) }

      context :work_package do
        let(:params) { { project_id: project.id,
                         format: :atom } }

        before { get :index, params }

        it { expect(assigns(:items).count).to eq(2) }

        it { expect(response).to render_template("common/feed") }
      end

      context :boards do
        let(:board) { FactoryGirl.create(:board,
                                         project: project) }
        let!(:message_1) { FactoryGirl.create(:message,
                                              board: board) }
        let!(:message_2) { FactoryGirl.create(:message,
                                              board: board) }
        let(:params) { { project_id: project.id,
                         show_messages: 1,
                         format: :atom } }

        before { get :index, params }

        it { expect(assigns(:items).count).to eq(2) }

        it { expect(response).to render_template("common/feed") }
      end
    end
  end
end
