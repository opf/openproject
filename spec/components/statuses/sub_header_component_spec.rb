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

RSpec.describe Statuses::SubHeaderComponent, type: :component do
  subject(:rendered_component) do
    with_request_url("/statuses") { render_inline(described_class.new(query:)) }
  end

  let(:query) { Queries::Statuses::StatusQuery.new(user: build(:admin)) }

  shared_let(:task) { create(:type, name: "Task") }
  shared_let(:manager) { create(:project_role, name: "Manager") }

  it "offers a quick filter per workflow facet", :aggregate_failures do
    expect(rendered_component).to have_css("[data-quick-filter--select-panel-filter-key-value='type']")
    expect(rendered_component).to have_css("[data-quick-filter--select-panel-filter-key-value='role']")
  end

  it "lists the eligible values in each panel", :aggregate_failures do
    expect(rendered_component).to have_css("[data-quick-filter--select-panel-filter-key-value='type'] [data-value]",
                                           text: "Task")
    expect(rendered_component).to have_css("[data-quick-filter--select-panel-filter-key-value='role'] [data-value]",
                                           text: "Manager")
  end

  it "wires the filters-form Stimulus controller, which the panels navigate through" do
    expect(rendered_component).to have_css("[data-controller='filter--filters-form']")
  end

  it "serializes the selection as JSON, which is what the controller parses" do
    expect(rendered_component)
      .to have_css("[data-filter--filters-form-output-format-value='json']")
  end

  it "links to the new status form" do
    expect(rendered_component).to have_link(href: "/statuses/new")
  end

  context "with an active filter" do
    before { query.where("type", "=", [task.id.to_s]) }

    it "opens the advanced panel so the active filter is visible" do
      expect(rendered_component).to have_css("[data-filter--filters-form-display-filters-value='true']")
    end
  end
end
