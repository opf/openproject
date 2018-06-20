#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'users/index', type: :view do
  let!(:admin) { FactoryGirl.create :admin }
  let!(:user) { FactoryGirl.create :user, firstname: "Scarlet", lastname: "Scallywag" }

  before do
    assign(:users, [admin, user])
    assign(:status, "all")
    assign(:groups, Group.all)

    allow(view).to receive(:current_user).and_return(admin)

    allow_any_instance_of(TableCell).to receive(:controller_name).and_return("users")
    allow_any_instance_of(TableCell).to receive(:action_name).and_return("index")
  end

  it 'renders the user table' do
    render

    expect(rendered).to have_text(admin.name)
    expect(rendered).to have_text("Scarlet Scallywag")
  end

  context "with an Enterprise token" do
    before do
      allow(OpenProject::Enterprise).to receive(:token).and_return(Struct.new(:restrictions).new({active_user_count: 5}))
    end

    it "shows the current number of active and allowed users" do
      render

      # expected active users: admin and user from above
      expect(rendered).to have_text("2/5 booked active users")
    end
  end

  context "without an Enterprise token" do
    it "does not show the current number of active and allowed users" do
      render

      expect(rendered).not_to have_text("booked active users")
    end
  end
end
