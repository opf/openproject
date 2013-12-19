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

describe MembersController do
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role) }
  let(:member) { FactoryGirl.create(:member, :project => project,
                                             :user => user,
                                             :roles => [role]) }

  before do
    User.stub(:current).and_return(user)
  end

  describe "update" do
    let(:admin) { FactoryGirl.create(:admin) }
    let(:project_2) { FactoryGirl.create(:project) }
    let(:role_1) { FactoryGirl.create(:role) }
    let(:role_2) { FactoryGirl.create(:role) }
    let(:member_2) { FactoryGirl.create(
      :member,
      :project => project_2,
      :user => admin,
      :roles => [role_1])
    }

    def dont_update(field, value)
      put :update,
        :project_id => project.identifier,
        :id => member_2.id,
        :member => {
          :role_ids => [role_1.id],
          field => value
        }

      response.should_not be_success
      Member.find(member_2.id).attributes[field.to_s].should_not == value
    end

    before do
      User.stub(:current).and_return(admin)
    end

    it "should specifically not allow 'user_id' to be mass assigned" do
      dont_update(:user_id, user.id)
    end

    it "should specifically not allow 'project_id' to be mass assigned" do
      dont_update(:project_id, project.id)
    end

    it "should specifically not allow 'created_on' to be mass assigned" do
      dont_update(:created_on, Time.zone.at(1111111111))
    end

    it "should specifically not allow 'mail_notification' to be mass assigned" do
      dont_update(:mail_notification, !member_2.mail_notification)
    end

    it "should, however, allow roles to be updated through mass assignment" do
      put 'update',
        :project_id => project.identifier,
        :id => member_2.id,
        :member => {
          :role_ids => [role_1.id, role_2.id]
        }

      Member.find(member_2.id).roles.should include(role_1, role_2)
      response.response_code.should < 400
    end
  end

  describe :autocomplete_for_member do
    let(:params) { ActionController::Parameters.new({ "id" => project.identifier.to_s }) }

    describe "WHEN the user is authorized
              WHEN a project is provided" do
      before do
        role.permissions << :manage_members
        role.save!
        member

        post :autocomplete_for_member, params, :format => :xhr
      end

      it "should be success" do
        response.should be_success
      end
    end

    describe "WHEN the user is not authorized" do
      before do
        post :autocomplete_for_member, params, :format => :xhr
      end

      it "should be forbidden" do
        response.response_code.should == 403
      end
    end
  end
end
