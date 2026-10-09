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

require "spec_helper"

RSpec.describe "Main menu first paint", :js do
  include FirstPaintSampling

  shared_let(:user) { create(:user) }

  before { login_as user }

  def collapse_menu
    visit root_path
    expect_angular_frontend_initialized
    click_on accessible_name: "Collapse project menu", match: :first
    expect(page).to have_css("#wrapper.hidden-navigation")
  end

  it "paints a collapsed menu on every frame of a full load" do
    collapse_menu

    start_first_paint_sampling
    page.refresh
    expect_angular_frontend_initialized

    expect(menu_hidden_in_every_frame?).to be(true), first_paint_frames.inspect
  end

  it "paints a collapsed menu on every frame of a Turbo visit" do
    start_first_paint_sampling
    collapse_menu
    page.execute_script("window.firstPaintSpecMarker = true")

    within("#content") { click_on "My page" }
    expect(page).to have_current_path(my_page_path)
    expect_angular_frontend_initialized

    expect(page.evaluate_script("window.firstPaintSpecMarker")).to be(true)
    expect(menu_hidden_in_every_frame?).to be(true), first_paint_frames.inspect
  end

  it "settles on the stored state once when the cookie is missing" do
    collapse_menu
    page.execute_script("document.cookie = 'op_main_menu_width=; path=/; max-age=0'")

    start_first_paint_sampling
    page.refresh
    expect_angular_frontend_initialized

    expect(menu_settles_hidden?).to be(true), first_paint_frames.inspect
    expect(page.driver.cookies["op_main_menu_width"].value).to eq("0")
  end

  context "on a narrow window" do
    include_context "with mobile screen size", 1000, 900

    it "never paints the open menu before the service runs" do
      start_first_paint_sampling
      visit root_path
      expect_angular_frontend_initialized

      expect(menu_hidden_in_every_frame?).to be(true), first_paint_frames.inspect
    end
  end

  it "fails loudly when the recorder was never installed" do
    visit root_path

    expect { first_paint_frames }.to raise_error(RuntimeError, /recorder not installed/)
  end
end
