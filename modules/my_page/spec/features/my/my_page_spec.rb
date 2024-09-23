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

require_relative "../../support/pages/my/page"

RSpec.describe "My page", :js do
  let!(:type) { create(:type) }
  let!(:project) { create(:project, types: [type]) }
  let!(:open_status) { create(:default_status) }
  let!(:created_work_package) do
    create(:work_package,
           project:,
           type:,
           author: user)
  end
  let!(:assigned_work_package) do
    create(:work_package,
           project:,
           type:,
           assigned_to: user)
  end

  let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages add_work_packages save_queries] })
  end
  let(:my_page) do
    Pages::My::Page.new
  end

  before do
    login_as user

    my_page.visit!
  end

  def grid
    @grid ||= Grids::MyPage.first
  end

  def reload_grid!
    @grid = Grids::MyPage.first
  end

  def assigned_area
    find_area("Work packages assigned to me")
  end

  def created_area
    find_area("Work packages created by me")
  end

  def calendar_area
    find_area("Calendar")
  end

  def news_area
    find_area("News")
  end

  def watched_area
    find_area("Work packages watched by me")
  end

  def find_area(name)
    retry_block do
      index = grid.widgets.sort_by(&:id).each_with_index.detect { |w, _index| w.options["name"] == name }.last

      Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(#{index + 1})")
    end
  end

  it "renders the default view, allows altering and saving" do
    # Waits for the default view to be created
    my_page.expect_toast(message: "Successful update")

    assigned_area.expect_to_exist
    created_area.expect_to_exist
    assigned_area.expect_to_span(1, 1, 2, 2)
    created_area.expect_to_span(1, 2, 2, 3)

    # The widgets load their respective contents
    expect(page)
      .to have_content(created_work_package.subject)
    expect(page)
      .to have_content(assigned_work_package.subject)

    # add widget above to right area
    my_page.add_widget(1, 1, :row, "Calendar")

    sleep(0.5)
    reload_grid!

    calendar_area.expect_to_span(1, 1, 2, 2)

    # resizing will move the created area down
    calendar_area.resize_to(1, 2)

    sleep(0.1)

    # resizing again will not influence the created area. It will stay down
    calendar_area.resize_to(1, 1)

    calendar_area.expect_to_span(1, 1, 2, 2)

    # add widget right next to the calendar widget
    my_page.add_widget(1, 2, :within, "News")

    sleep(0.5)
    reload_grid!

    news_area.expect_to_span(1, 2, 2, 3)

    calendar_area.resize_to(2, 1)

    sleep(0.3)

    # Resizing leads to the calendar area now spanning a larger area
    calendar_area.expect_to_span(1, 1, 3, 2)
    # Because of the added row, and the resizing the other widgets (assigned and created) have moved down
    assigned_area.expect_to_span(3, 1, 4, 2)
    created_area.expect_to_span(2, 2, 3, 3)

    my_page.add_widget(1, 3, :column, "Work packages watched by me")

    sleep(0.5)
    reload_grid!

    watched_area.expect_to_exist

    sleep(1)

    # dragging makes room for the dragged widget which means
    # that widgets that have been there are moved down
    created_area.drag_to(1, 3)

    my_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

    reload_grid!

    calendar_area.expect_to_span(1, 1, 3, 2)
    watched_area.expect_to_span(2, 3, 3, 4)
    assigned_area.expect_to_span(3, 1, 4, 2)
    created_area.expect_to_span(1, 3, 2, 4)
    news_area.expect_to_span(1, 2, 2, 3)

    # dragging again makes room for the dragged widget which means
    # that widgets that have been there are moved down. Additionally,
    # as no more widgets start in the second column, that column is removed
    news_area.drag_to(1, 3)

    my_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

    reload_grid!

    # Reloading keeps the user's values
    visit home_path
    my_page.visit!

    calendar_area.expect_to_span(1, 1, 3, 2)
    news_area.expect_to_span(1, 2, 2, 3)
    created_area.expect_to_span(2, 2, 3, 3)
    assigned_area.expect_to_span(3, 1, 4, 2)
    watched_area.expect_to_span(3, 2, 4, 3)
  end
end
