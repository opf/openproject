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

RSpec.describe "Reordering types in a type scheme", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:story) { create(:type, name: "Story") }
  shared_let(:scheme) { create(:type_scheme, name: "Dev", types: [epic, story]) }

  current_user { admin }

  it "moves a row with the arrow buttons and saves the new order" do
    visit edit_admin_type_scheme_path(scheme)

    click_button "Move Epic down"
    expect(page).to have_css("[role=status]", text: "Epic moved to position 2 of")

    click_button "Save"
    expect(page).to have_text("Successful update.")
    expect(scheme.reload.types.first(2)).to eq [story, epic]
  end
end
