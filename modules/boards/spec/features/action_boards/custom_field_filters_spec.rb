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
require_relative "../support//board_index_page"
require_relative "../support/board_page"

RSpec.describe "Custom field filter in boards", :js, with_ee: %i[board_view] do
  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let(:type) { create(:type_standard) }
  let(:project) { create(:project, types: [type], enabled_module_names: %i[work_package_tracking board_view]) }
  let(:role) { create(:project_role, permissions:) }

  let(:board_index) { Pages::BoardIndex.new(project) }

  let(:permissions) do
    %i[show_board_views manage_board_views add_work_packages
       edit_work_packages view_work_packages manage_public_queries]
  end

  let!(:priority) { create(:default_priority) }
  let!(:open_status) { create(:default_status, name: "Open") }
  let!(:closed_status) { create(:status, is_closed: true, name: "Closed") }

  let!(:work_package) do
    wp = build(:work_package,
               project:,
               type:,
               subject: "Foo",
               status: open_status)

    wp.custom_field_values = {
      custom_field.id => %w[B].map { |s| custom_value_for(s) }
    }

    wp.save
    wp
  end

  let(:filters) { Components::WorkPackages::Filters.new }

  let(:custom_field) do
    create(
      :list_wp_custom_field,
      name: "Ingredients",
      multi_value: true,
      types: [type],
      projects: [project],
      possible_values: %w[A B C]
    )
  end

  def custom_value_for(str)
    custom_field.custom_options.find { |co| co.value == str }.try(:id)
  end

  before do
    project
    login_as(user)
  end

  it "can add a case-insensitive list (Regression #35744)" do
    board_index.visit!

    # Create new board
    board_page = board_index.create_board action: "Status"

    # expect lists of default status
    board_page.expect_list "Open"

    # Add a filter for CF value A and B
    filters.expect_filter_count 0
    filters.open

    filters.add_filter_by(custom_field.name,
                          "is (OR)",
                          %w[A B],
                          custom_field.attribute_name(:camel_case))

    board_page.expect_changed

    # Save that filter
    board_page.save

    board_page.add_list option: "Closed", query: "closed"
    board_page.expect_list "Closed"

    # Expect card to be present
    board_page.expect_card("Open", "Foo", present: true)

    # Move card to list closed
    board_page.move_card(0, from: "Open", to: "Closed")

    board_page.expect_card("Closed", "Foo", present: true)
    board_page.expect_card("Open", "Foo", present: false)

    # Expect custom field to be unchanged
    work_package.reload
    cv = work_package.custom_value_for(custom_field).typed_value
    expect(cv).to eq "B"
  end
end
