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
  shared_let(:member_of_department) { create(:user, login: "with-department") }
  shared_let(:without_department) { create(:user, login: "without-department") }
  shared_let(:department) { create(:department, lastname: "Research", members: [member_of_department]) }

  let(:query) do
    UserQuery.new(name: "Users").tap { it.select(:login, :department) }
  end

  before do
    login_as(admin)
    vc_test_controller.action_name = "index"
    vc_test_controller.request.path_parameters = { controller: "users", action: "index" }
    render_inline(described_class.new(rows: query, current_user: admin))
  end

  it "renders the department column header" do
    expect(page).to have_css("th", text: User.human_attribute_name(:department))
  end

  it "renders the department of each user" do
    expect(page).to have_css("td.department", text: department.name, count: 1)
    expect(page).to have_css("tr.user td.department", count: 3)
  end
end
