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

require "spec_helper"

RSpec.describe "Paginated type ordering", :js, :selenium,
               with_settings: { per_page_options: "2,100" } do
  shared_let(:admin) { create(:admin) }
  shared_let(:types) { %w[A B C D E].map { |name| create(:type, name:) } }

  before { login_as(admin) }

  def type_list
    find(:list, accessible_name: I18n.t(:label_type_plural))
  end

  def expect_page_types(*names)
    page.document.synchronize do
      found = type_list.all(:xpath, "./*[@role='listitem']//h4//a").map(&:text)
      raise Capybara::ExpectationNotMet, "Expected #{names}, got #{found}" unless found == names
    end
  end

  def type_group(type)
    find(:link, type.name, href: type_settings_path(type_id: type.id)).ancestor(:list_item)
  end

  def move_type(type, direction)
    wait_for_turbo_stream do
      within(type_group(type)) do
        within(".Box-header") do
          find(:button, accessible_name: I18n.t(:label_actions)).click
          click_on I18n.t(:button_move)
          click_on I18n.t(direction)
        end
      end
    end
  end

  def drag_last_before_first
    wait_for_turbo_stream do
      Pages::Page.new.drag_and_drop_list(
        from: 1, to: 0,
        elements: ".op-types-sortable-list > [role='listitem']",
        handler: "[data-sortable-lists--item-target~='handle']"
      )
    end
  end

  def expect_order(*names)
    expect(Type.order(:position).pluck(:name)).to eq(names)
  end

  it "reorders twice on page two across morphs and persists on reload" do
    visit types_path(page: 2, per_page: 2)
    expect_page_types("C", "D")

    drag_last_before_first
    expect_page_types("D", "C")
    expect_order("A", "B", "D", "C", "E")

    drag_last_before_first
    expect_page_types("C", "D")
    expect_order("A", "B", "C", "D", "E")

    page.refresh
    expect_page_types("C", "D")
    expect(page).to have_current_path(types_path(page: 2, per_page: 2))
  end

  it "moves up across pages and refreshes the next lazy menu" do
    visit types_path(page: 2, per_page: 2)
    move_type(types[2], :label_sort_higher)

    expect_page_types("B", "D")
    expect_order("A", "C", "B", "D", "E")
    expect(page).to have_text(I18n.t(:notice_successful_update))
    expect(page).to have_current_path(types_path(page: 2, per_page: 2))

    move_type(types[1], :label_sort_higher)
    expect_page_types("C", "D")
    expect_order("A", "B", "C", "D", "E")
  end

  it "moves to the global top while keeping index pagination links" do
    visit types_path(page: 2, per_page: 2)
    move_type(types[3], :label_sort_highest)

    expect_page_types("B", "C")
    expect_order("D", "A", "B", "C", "E")
    page.refresh
    expect_page_types("B", "C")

    within(".op-pagination--pages") { click_on "1" }
    expect_page_types("D", "A")
    expect(page).to have_current_path(types_path(page: 1, per_page: 2))
  end

  it "moves down into the next page" do
    visit types_path(page: 2, per_page: 2)
    move_type(types[3], :label_sort_lower)

    expect_page_types("C", "E")
    expect_order("A", "B", "C", "E", "D")
  end

  it "moves to the global bottom" do
    visit types_path(page: 2, per_page: 2)
    move_type(types[2], :label_sort_lowest)

    expect_page_types("D", "E")
    expect_order("A", "B", "D", "E", "C")
  end

  it "moves expanded groups without mixing their variants or matching nested rows" do
    types[2].update!(name: "Bug")
    types[3].update!(name: "Bugfix")
    zeta = create(:type_variant, type: types[2], variant_name: "Zeta")
    alpha = create(:type_variant, type: types[2], variant_name: "Alpha")
    visit types_path(page: 2, per_page: 2, expand: types[2].id)
    expect_page_types("Bug", "Bugfix")

    using_wait_time(0) do
      expect { expect_page_types("Bugfix", "Bug") }.to raise_error(Capybara::ExpectationNotMet)
    end

    drag_last_before_first
    expect_page_types("Bugfix", "Bug")
    expect_order("A", "B", "Bugfix", "Bug", "E")
    within(type_group(types[2])) do
      expect(page).to have_link("Alpha")
      expect(page).to have_link("Zeta")
    end
    expect(types[2].variants.non_default_variants.in_display_order).to eq([alpha, zeta])
  end
end
