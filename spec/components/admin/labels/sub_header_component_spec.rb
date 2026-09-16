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

require "rails_helper"

RSpec.describe Admin::Labels::SubHeaderComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:rendered_component) do
    with_request_url "/admin/labels" do
      render_inline(described_class.new(query:))
    end
  end

  let(:query) { Queries::Labels::LabelQuery.new }

  it "wires the filters-form controller to the search endpoint" do
    rendered_component

    header = page.find("[data-test-selector='labels-sub-header']", visible: :all)
    expect(header["data-controller"]).to eq("filter--filters-form")
    expect(header["data-filter--filters-form-url-path-name-value"]).to eq(search_admin_labels_path)
  end

  it "renders the search input without a value when no filter is active" do
    rendered_component

    expect(page.find_field("Search", visible: :all).value).to be_blank
  end

  it "prefills the search input from an active name filter" do
    query.where(:name, "~", ["urgent"])

    rendered_component

    expect(page).to have_field("Search", with: "urgent", visible: :all)
  end

  it "renders the add label button pointing at the create dialog" do
    rendered_component

    expect(page).to have_css(
      "a[href='#{new_dialog_admin_labels_path}'][data-controller='async-dialog']",
      text: "Label"
    )
  end

  it "gives the add label button an aria-label distinct from its visible text" do
    rendered_component

    expect(page).to have_css("a[aria-label='Add label']", text: "Label")
  end
end
