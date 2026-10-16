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

RSpec.describe "hourly rates on a member", :js do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:admin, member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
  end

  let(:member) { Member.find_by(project:, principal: user) }

  before do
    login_as(user)
  end

  def expect_current_rate_in_members_table(amount)
    visit project_members_path(project)

    expect(page).to have_css("#member-#{member.id} .currency", text: amount)
  end

  context "without any rate" do
    it "falls back to zero" do
      expect_current_rate_in_members_table("0.00 €")
    end
  end

  context "with rates taking effect on different dates" do
    before do
      create(:hourly_rate, principal: user, project:, valid_from: 5.days.ago, rate: 20)
      create(:hourly_rate, principal: user, project:, valid_from: Date.current, rate: 10)
    end

    it "displays the rate in effect today and links to the rate history" do
      expect_current_rate_in_members_table("10.00 €")

      click_link("10.00 €")

      expect(page).to have_current_path(projects_hourly_rate_path(project_id: project, id: user))
    end
  end
end
