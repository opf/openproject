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

RSpec.describe Widget::GroupBys, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:cost_query) { build_stubbed(:cost_report, public: true) }
  let(:options) { {} }

  subject(:rendered_component) do
    render_component(cost_query, **options)
  end

  it "renders component" do
    expect(rendered_component).to have_element id: "group-by--area"
  end

  it "renders 'selected columns' fieldset" do
    expect(rendered_component).to have_selector :fieldset, "Selected columns"
  end

  it "renders 'selected rows' fieldset" do
    expect(rendered_component).to have_selector :fieldset, "Selected rows"
  end

  it "renders 'add group by' selects" do
    expect(rendered_component).to have_select "Add Group-by Attribute", count: 2
    expect(rendered_component).to have_select "Add Group-by Attribute", fieldset: "Selected columns"
    expect(rendered_component).to have_select "Add Group-by Attribute", fieldset: "Selected rows"
  end

  context "with no groupings applied" do
    it "renders empty columns data" do
      expect(rendered_component).to have_element id: "group-by--columns" do |div|
        expect(div["data-initially-selected"]).to eql "[]"
      end
    end

    it "renders empty rows data" do
      expect(rendered_component).to have_element id: "group-by--rows" do |div|
        expect(div["data-initially-selected"]).to eql "[]"
      end
    end
  end

  context "with some groupings applied" do
    before do
      cost_query.group_by :spent_on
      cost_query.group_by :project_id
      cost_query.row :user_id
    end

    it "renders columns data" do
      expect(rendered_component).to have_element id: "group-by--columns" do |div|
        expect(div["data-initially-selected"]).to eql "[['project_id','Project'],['spent_on','Date (Spent)']]"
      end
    end

    it "renders rows data" do
      expect(rendered_component).to have_element id: "group-by--rows" do |div|
        expect(div["data-initially-selected"]).to eql "[['user_id','User']]"
      end
    end
  end
end
