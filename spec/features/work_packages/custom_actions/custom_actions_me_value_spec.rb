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

require "spec_helper"

RSpec.describe "Custom actions me value", :js, :with_cuprite, with_ee: %i[custom_actions] do
  shared_let(:admin) { create(:admin) }

  let(:permissions) { %i(view_work_packages edit_work_packages) }
  let(:role) { create(:project_role, permissions:) }
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:type) { create(:type_task) }
  let(:project) { create(:project, types: [type], name: "This project") }
  let!(:custom_field) { create(:user_wp_custom_field, types: [type], projects: [project]) }
  let!(:work_package) do
    create(:work_package,
           type:,
           project:)
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:default_priority) do
    create(:default_priority, name: "Normal")
  end
  let(:index_ca_page) { Pages::Admin::CustomActions::Index.new }

  before do
    login_as(admin)
  end

  it "can assign user custom field to self" do
    # create custom action 'Unassign'
    index_ca_page.visit!

    new_ca_page = index_ca_page.new
    new_ca_page.set_name("Set CF to me")
    new_ca_page.add_action(custom_field.name, I18n.t("custom_actions.actions.assigned_to.executing_user_value"))

    new_ca_page.create

    assign = CustomAction.last
    expect(assign.actions.length).to eq(1)
    expect(assign.conditions.length).to eq(0)
    expect(assign.actions.first.values).to eq(["current_user"])

    login_as user
    wp_page.visit!

    wp_page.expect_custom_action("Set CF to me")
    wp_page.click_custom_action("Set CF to me")
    wp_page.expect_attributes "customField#{custom_field.id}": user.name
  end
end
