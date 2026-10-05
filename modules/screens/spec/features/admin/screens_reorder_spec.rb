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
# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin screen reorder", :js do # rubocop:disable RSpec/DescribeClass
  current_user { create(:admin) }

  let(:screen) { create(:create_screen) }
  let(:section) { create(:screen_section, screen:, name: "General") }

  before do
    create(:screen_item, screen:, section:, field_key: "subject", position: 1)
    create(:screen_item, screen:, section:, field_key: "priority", position: 2)
  end

  it "moves an item with the keyboard and keeps focus" do
    visit edit_admin_screen_path(screen)

    item = find("#screen-item-#{screen.items.find_by(field_key: 'priority').id}")
    item.find("input[data-screens--sortable-target='itemPosition']").click
    item.send_keys([:alt, :arrow_up])

    expect(page).to have_css("[aria-live]")
    expect(find("input[name*='[items][0][field_key]']", visible: false).value).to eq("priority")
    expect(item).to have_focus
  end

  it "is accessible" do
    visit edit_admin_screen_path(screen)
    expect(page).to be_axe_clean.within("#content")
  end
end
