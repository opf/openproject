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

RSpec.describe Widget::Filters, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:cost_query) { build_stubbed(:cost_report, public: true) }
  let(:options) { {} }

  subject(:rendered_component) do
    with_controller_class(Reporting::CostReportsController) do
      with_request_url("/reporting/cost_reports") do
        render_component(cost_query, **options)
      end
    end
  end

  context "with no filters applied" do
    it "renders no filters" do
      expect(rendered_component).to have_list id: "filter_table" do |list|
        expect(list).to have_list_item class: "advanced-filters--filter", count: 0
        expect(list).to have_list_item class: "advanced-filters--spacer"
        expect(list).to have_list_item class: "advanced-filters--add-filter"
      end
    end

    it "renders select with available filters" do
      expect(rendered_component).to have_select "add_filter_select", with_options: ["Status", "Created on"]
    end
  end

  context "with some filters applied" do
    before do
      cost_query.filter :status_id, operator: "o"
      cost_query.filter :created_on, operator: "t"
    end

    it "renders filters" do
      expect(rendered_component).to have_list id: "filter_table" do |list|
        expect(list).to have_list_item class: "advanced-filters--filter", count: 2
        expect(list).to have_list_item class: "advanced-filters--spacer"
        expect(list).to have_list_item class: "advanced-filters--add-filter"
      end
    end
  end
end
