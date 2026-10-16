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

RSpec.describe "Placeholder user filter criteria", :js, with_ee: %i[placeholder_users] do
  shared_let(:matching_user) { create(:user, firstname: "Dev", lastname: "Eloper") }

  # Each example edits its placeholder's criteria, so they cannot share one.
  let!(:without_criteria) { create(:placeholder_user, name: "Just a seat") }

  let!(:with_criteria) do
    query = UserQuery.new
    query.where("name", "~", ["Eloper"])
    create(:placeholder_user, name: "Senior Developer", user_filter: query.filters)
  end

  current_user { create(:admin) }

  def toggle
    find('[data-test-selector="placeholder-user-criteria-toggle"]')
  end

  it "offers the filter builder right after activating the criteria" do
    visit edit_placeholder_user_path(without_criteria, tab: :criteria)

    expect(page).to have_text(I18n.t("placeholder_users.criteria.activate"))
    expect(page).to have_no_css(".op-filters-form")

    toggle.click

    expect(page).to have_css(".op-filters-form")
    expect(toggle).to have_css("button[aria-pressed='true']")
    expect(toggle).to have_no_css("button[disabled]")
  end

  it "stores the criteria as they are edited and refreshes the users they select" do
    other_user = create(:user, firstname: "Sales", lastname: "Person")

    visit edit_placeholder_user_path(with_criteria, tab: :criteria)

    expect(page).to have_text(matching_user.name)
    expect(page).to have_no_button(I18n.t(:button_save))

    fill_in "name_value", with: "Person"

    expect(page).to have_text(other_user.name)
    expect(page).to have_no_text(matching_user.name)
    expect(with_criteria.reload.user_filter.first.values).to eq(["Person"])
  end

  it "drops the criteria when deactivating them" do
    visit edit_placeholder_user_path(with_criteria, tab: :criteria)

    expect(page).to have_text(I18n.t("placeholder_users.criteria.matching_users"))
    expect(page).to have_text(matching_user.name)

    toggle.click

    expect(page).to have_no_css(".op-filters-form")
    expect(with_criteria.reload.user_filter).to be_empty
  end
end
