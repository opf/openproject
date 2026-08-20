# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../spec_helper"

RSpec.describe "rate history on the user rates tab" do
  shared_let(:admin) { create(:admin) }
  shared_let(:user) { create(:user) }

  shared_let(:member_project) { create(:project, name: "Member project", member_with_permissions: { user => [] }) }
  shared_let(:former_member_project) { create(:project, name: "Former member project") }
  shared_let(:unrelated_project) { create(:project, name: "Unrelated project") }

  shared_let(:member_rate) { create(:hourly_rate, user:, project: member_project) }
  shared_let(:former_member_rate) { create(:hourly_rate, user:, project: former_member_project) }

  def rate_history_for(project)
    page.find(".user-rate-history-list", text: project.name)
  end

  before do
    login_as admin
    visit edit_user_path(user, tab: "rates")
  end

  it "allows updating the rates of a project the user is a member of" do
    within rate_history_for(member_project) do
      expect(page).to have_link I18n.t(:button_update)
    end
  end

  it "shows the rates of a project the user is no longer a member of without an update link" do
    within rate_history_for(former_member_project) do
      expect(page).to have_css("table.rates td", text: former_member_rate.valid_from.to_s)
      expect(page).to have_no_link I18n.t(:button_update)
    end
  end

  it "does not show a project the user is neither a member of nor has rates in" do
    expect(page).to have_no_css(".user-rate-history-list", text: unrelated_project.name)
  end
end
