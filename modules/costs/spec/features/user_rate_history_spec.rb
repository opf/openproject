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

  shared_let(:rateless_project) { create(:project, name: "Rateless project", member_with_permissions: { user => [] }) }

  shared_let(:member_rate) { create(:hourly_rate, user:, project: member_project) }
  shared_let(:former_member_rate) { create(:hourly_rate, user:, project: former_member_project) }
  shared_let(:default_rate) { create(:default_hourly_rate, principal: user, rate: 30) }

  def rate_history_for(project)
    page.find("[data-test-selector='rate-history-project-#{project.id}']")
  end

  before do
    login_as admin
    visit edit_user_path(user, tab: "rates")
  end

  it "shows the rate of a project the user is a member of" do
    within rate_history_for(member_project) do
      expect(page).to have_text member_project.name
      expect(page).to have_text "#{I18n.t(:label_current)}: #{format('%.2f', member_rate.rate)}"
    end
  end

  it "shows the rate of a project the user is no longer a member of" do
    within rate_history_for(former_member_project) do
      expect(page).to have_text format("%.2f", former_member_rate.rate)
    end
  end

  it "falls back to the default rate for a project without a rate of its own" do
    within rate_history_for(rateless_project) do
      expect(page).to have_text "#{I18n.t(:label_using_current_default_rate)}: #{format('%.2f', default_rate.rate)}"
    end
  end

  it "renders every project as a section that starts collapsed" do
    [member_project, former_member_project].each do |project|
      within rate_history_for(project) do
        expect(page).to have_css("[data-collapsible-toggle][aria-expanded='false']")
        expect(page).to have_css("[role='region']", visible: :hidden)
      end
    end
  end

  it "does not show a project the user is neither a member of nor has rates in" do
    expect(page).to have_no_css("[data-test-selector='rate-history-project-#{unrelated_project.id}']")
  end
end
