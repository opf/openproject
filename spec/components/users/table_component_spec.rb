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

require "rails_helper"

RSpec.describe Users::TableComponent, type: :component do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project, name: "Apple") }
  shared_let(:other_project) { create(:project, name: "Banana") }
  shared_let(:user) do
    create(:user,
           login: "connected",
           status: :locked,
           consented_at: Time.zone.parse("2026-03-04T10:00:00Z"),
           member_with_permissions: { project => [:view_project], other_project => [:view_project] })
  end
  shared_let(:lonely_user) { create(:user, login: "unconnected") }
  shared_let(:department) { create(:department, lastname: "Research", members: [user]) }
  shared_let(:group) { create(:group, lastname: "Reviewers", members: [user]) }

  let(:selects) { %i[login department member_of_group member_of_project status] }

  let(:query) do
    UserQuery.new(name: "Users").tap { it.select(*selects) }
  end

  before do
    login_as(admin)
    vc_test_controller.action_name = "index"
    vc_test_controller.request.path_parameters = { controller: "users", action: "index" }
    render_inline(described_class.new(rows: query, current_user: admin))
  end

  it "renders a header for every selected column" do
    captions = [User.human_attribute_name(:login),
                User.human_attribute_name(:department),
                I18n.t(:label_member_of_group),
                I18n.t(:label_member_of_project),
                I18n.t(:label_status)]

    captions.each { expect(page).to have_css("th", text: it) }
  end

  it "renders the department with a briefcase icon" do
    expect(page).to have_css("td.department", text: department.name, count: 1)
    expect(page).to have_css("td.department .octicon-briefcase", count: 1)
  end

  it "renders the groups without the department" do
    expect(page).to have_css("td.member_of_group", text: group.name, count: 1)
    expect(page).to have_no_css("td.member_of_group", text: department.name)
  end

  it "renders the projects in alphabetical order" do
    expect(page).to have_css("td.member_of_project", text: "Apple, Banana", count: 1)
  end

  it "renders the status" do
    expect(page).to have_css("td.status", text: I18n.t(:status_locked), count: 1)
    expect(page).to have_css("td.status", text: I18n.t(:status_active), count: 2)
  end

  context "with the consent column", with_settings: { consent_required: true } do
    let(:selects) { %i[login consented_at] }

    it "renders the formatted consent time of a user who consented" do
      expect(page).to have_css("th", text: User.human_attribute_name(:consented_at))
      expect(page).to have_css("td.consented_at",
                               text: ApplicationController.helpers.format_time(user.consented_at),
                               count: 1)
    end

    it "leaves the cell empty for a user who never consented" do
      row = page.find("tr.user", text: lonely_user.login)

      expect(row.find("td.consented_at").text).to be_blank
    end
  end

  it "leaves the cells of an unconnected user empty" do
    row = page.find("tr.user", text: lonely_user.login)

    expect(row.find("td.department").text).to be_blank
    expect(row.find("td.member_of_group").text).to be_blank
    expect(row.find("td.member_of_project").text).to be_blank
  end
end
