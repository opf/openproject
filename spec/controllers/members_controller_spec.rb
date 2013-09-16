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
