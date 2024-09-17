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

RSpec.describe "Work Package boards updating spec", :js, with_ee: %i[board_view] do
  let(:admin) { create(:admin) }

  let(:project) { create(:project, enabled_module_names: %i[work_package_tracking board_view]) }
  let!(:priority) { create(:default_priority) }
  let!(:status) { create(:default_status) }

  let(:board_index) { Pages::BoardIndex.new(project) }
  let!(:board_view) { create(:board_grid_with_query, name: "My board", project:) }

  before do
    project
    login_as(admin)
    board_index.visit!
  end

  it "Changing the title in the split screen, updates the card automatically" do
    board_page = board_index.open_board board_view
    board_page.expect_query "List 1", editable: true
    board_page.add_card "List 1", "Foo Bar"
    board_page.expect_toast message: I18n.t(:notice_successful_create)

    work_package = WorkPackage.last
    expect(work_package.subject).to eq "Foo Bar"

    # Open in split view
    card = board_page.card_for(work_package)
    split_view = card.open_details_view
    split_view.expect_subject
    split_view.edit_field(:subject).update("My super cool new title")

    split_view.expect_and_dismiss_toaster message: "Successful update."
    card.expect_subject "My super cool new title"
  end
end
