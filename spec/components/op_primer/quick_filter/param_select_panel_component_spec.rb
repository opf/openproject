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

RSpec.describe OpPrimer::QuickFilter::ParamSelectPanelComponent, type: :component do
  subject(:rendered_component) do
    with_request_url("/statuses") do
      render_inline(
        described_class.new(
          title: "Filter by type",
          param: "type_ids",
          records: types,
          selected:,
          all_label: "All types",
          many_label_key: "statuses.index.filter.types"
        )
      )
    end
  end

  let(:task) { create(:type, name: "Task") }
  let(:bug) { create(:type, name: "Bug") }
  let(:types) { [task, bug] }
  let(:selected) { [] }

  it "drives the select panel element itself, which holds the item checked state" do
    expect(rendered_component).to have_css(
      "select-panel[data-controller='quick-filter--param-select-panel']" \
      "[data-quick-filter--param-select-panel-param-value='type_ids']"
    )
  end

  describe "button label" do
    it "reads as unfiltered when nothing is selected" do
      expect(rendered_component).to have_button(text: "All types")
    end

    context "with one record selected" do
      let(:selected) { [task] }

      it "names it" do
        expect(rendered_component).to have_button(text: "Task")
      end
    end

    context "with several records selected" do
      let(:selected) { [task, bug] }

      it "counts them" do
        expect(rendered_component).to have_button(text: "2 types")
      end
    end
  end
end
