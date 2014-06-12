#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe MyProjectsOverviewsController do
  before :each do
    allow(@controller).to receive(:set_localization)
    expect(@controller).to receive(:authorize)

    @role = FactoryGirl.create(:non_member)
    @user = FactoryGirl.create(:admin)

    allow(User).to receive(:current).and_return @user

    @params = {}
  end

  let(:project) { FactoryGirl.create(:project) }

  describe 'index' do
    let(:params) { { "id" => project.id.to_s } }

    describe "WHEN calling the page" do
      render_views

      before do
        get 'index', params
      end

      it 'renders the overview page' do
        expect(response).to be_success
        expect(response).to render_template 'index'
      end
    end

    describe "WHEN calling the page
              WHEN providing a jump parameter" do

      before do
        params["jump"] = "work_packages"
        get 'index', params
      end

      it { expect(response).to redirect_to project_work_packages_path(project) }
    end
  end
end
