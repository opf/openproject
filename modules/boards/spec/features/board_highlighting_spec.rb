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
require_relative "support/board_index_page"
require_relative "support/board_page"

RSpec.describe "Work Package boards spec", :js, with_ee: %i[board_view] do
  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let(:project) { create(:project, enabled_module_names: %i[work_package_tracking board_view]) }
  let(:permissions) { %i[show_board_views manage_board_views add_work_packages view_work_packages manage_public_queries] }
  let(:role) { create(:project_role, permissions:) }

  let!(:wp) do
    create(:work_package,
           project:,
           type:,
           priority:,
           status: open_status)
  end
  let!(:wp2) do
    create(:work_package,
           project:,
           type: type2,
           priority: priority2,
           status: open_status)
  end

  let!(:priority) { create(:priority, color:) }
  let!(:priority2) { create(:priority, color: color2) }
  let!(:type) { create(:type, color:) }
  let!(:type2) { create(:type, color: color2) }
  let!(:open_status) { create(:default_status, name: "Open") }

  let(:board_index) { Pages::BoardIndex.new(project) }

  let(:color) { create(:color) }
  let(:color2) { create(:color) }

  before do
    project
    login_as(user)
  end

  it "navigates from boards to the WP full view and back" do
    board_index.visit!

    board_page = board_index.create_board action: "Status"

    # See the work packages
    board_page.expect_query "Open", editable: false
    board_page.expect_card "Open", wp.subject
    board_page.expect_card "Open", wp2.subject

    # Highlight type inline is always active
    expect(page).to have_css(".__hl_inline_type_#{type.id}")
    expect(page).to have_css(".__hl_inline_type_#{type2.id}")

    # Highlight whole card by priority
    board_page.change_board_highlighting "inline", "Priority"
    expect(page).to have_css(".__hl_background_priority_#{priority.id}")
    expect(page).to have_css(".__hl_background_priority_#{priority2.id}")

    # Highlight whole card by type
    board_page.change_board_highlighting "inline", "Type"
    expect(page).to have_css(".__hl_background_type_#{type.id}")
    expect(page).to have_css(".__hl_background_type_#{type2.id}")

    # Disable highlighting
    board_page.change_board_highlighting "none"
    expect(page).to have_no_css(".__hl_background_type_#{type.id}")
    expect(page).to have_no_css(".__hl_background_type_#{type2.id}")

    # Type is still shown highlighted
    expect(page).to have_css(".__hl_inline_type_#{type.id}")
    expect(page).to have_css(".__hl_inline_type_#{type2.id}")
  end
end
