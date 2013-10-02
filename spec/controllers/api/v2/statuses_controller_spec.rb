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

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::V2::StatusesController do

  let(:valid_user) { FactoryGirl.create(:user) }
  let(:status)     {FactoryGirl.create(:status)}

  before do
    User.stub(:current).and_return valid_user
  end

  describe 'authentication of index' do
    def fetch
      get 'index', :format => 'json'
    end
    it_should_behave_like "a controller action with require_login"
  end

  describe 'authentication of show' do
    def fetch
      get 'show', :format => 'json', :id => status.id
    end
    it_should_behave_like "a controller action with require_login"
  end

  describe 'looking up a singular status' do
    let(:closed){FactoryGirl.create(:status, name: "Closed")}

    it 'that does not exist should raise an error' do
      get 'show', :id => '0', :format => 'json'
      response.response_code.should == 404
    end
    it 'that exists should return the proper status' do
      get 'show', :id => closed.id, :format => 'json'
      expect(assigns(:status)).to eql closed
    end

  end

  describe 'looking up statuses' do

    let(:open) {FactoryGirl.create(:status, name: "Open")}
    let(:in_progress) {FactoryGirl.create(:status, name: "In Progress")}
    let(:closed){FactoryGirl.create(:status, name: "Closed")}
    let(:no_see_status){FactoryGirl.create(:status, name: "You don't see me.")}

    let(:workflows) do
      workflows = [FactoryGirl.create(:workflow, old_status: open, new_status: in_progress, role: role),
                   FactoryGirl.create(:workflow, old_status: in_progress, new_status: closed, role: role)]
    end

    let(:no_see_workflows) do
      workflows = [FactoryGirl.create(:workflow, old_status: closed, new_status: no_see_status, role: role)]
    end

    let(:project) do
      type = FactoryGirl.create(:type, name: "Standard", workflows: workflows)
      project = FactoryGirl.create(:project, types: [type])
    end
    let(:invisible_project) do
      invisible_type = FactoryGirl.create(:type, name: "No See", workflows: no_see_workflows)
      project = FactoryGirl.create(:project, types: [invisible_type], is_public: false)
    end

    let(:role) { FactoryGirl.create(:role) }
    let(:member) { FactoryGirl.create(:member, :project => project,
                                        :user => valid_user,
                                        :roles => [role]) }


    before do
      member
      workflows
    end

    describe 'with project-scope' do
      it 'with unknown project raises ActiveRecord::RecordNotFound errors' do
        get 'index', :project_id => '0', :format => 'json'
        expect(response.response_code).to eql 404
      end

      it "should return the available statuses _only_ for the given project" do
        get 'index', :project_id => project.id, :format => 'json'
        expect(assigns(:statuses)).to include open, in_progress, closed
        expect(assigns(:statuses)).not_to include no_see_status
      end

    end

    describe 'without project-scope' do
      it "should return only status for visible projects" do
        # create the invisible type/workflow/status
        invisible_project
        get 'index', :format => 'json'

        expect(assigns(:statuses)).to include open, in_progress, closed
        expect(assigns(:statuses)).not_to include no_see_status
      end
    end
  end

end

