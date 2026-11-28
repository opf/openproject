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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe CustomElementHelper do
  def render_tag(**)
    Capybara.string(helper.custom_element_tag.opce_principal(**))
  end

  it "dasherizes the element name and attribute keys" do
    html = helper.custom_element_tag.opce_principal(hover_card_url: "/x")
    expect(html).to eq('<opce-principal hover-card-url="/x"></opce-principal>')
  end

  it "renders numbers as strings" do
    expect(render_tag(size: 3)).to have_css("opce-principal[size='3']")
  end

  it "renders true as a bare attribute" do
    expect(render_tag(link: true)).to have_css("opce-principal[link='']")
  end

  it "renders false as the string false" do
    expect(render_tag(link: false)).to have_css("opce-principal[link='false']")
  end

  it "omits nil attributes" do
    expect(helper.custom_element_tag.opce_principal(name_title: nil)).not_to include("name-title")
  end

  it "serializes hashes as escaped JSON" do
    html = helper.custom_element_tag.opce_principal(principal: { id: 1, name: "<b>Ann</b>" })
    value = Capybara.string(html).find("opce-principal")["principal"]

    expect(JSON.parse(value)).to eq("id" => 1, "name" => "<b>Ann</b>")
    expect(html).not_to include("<b>")
  end

  it "serializes arrays as JSON" do
    value = Capybara.string(helper.custom_element_tag.opce_principal(ids: %w[a b])).find("opce-principal")["ids"]

    expect(JSON.parse(value)).to eq(%w[a b])
  end

  it "treats HTML boolean attributes as presence" do
    expect(helper.custom_element_tag.opce_principal(disabled: false)).not_to include("disabled")
    expect(render_tag(disabled: true)).to have_css("opce-principal[disabled]")
  end

  it "passes class and data through" do
    html = render_tag(class: "x", data: { test_selector: "y" })
    expect(html).to have_css("opce-principal.x[data-test-selector='y']")
  end

  it "renders content" do
    expect(helper.custom_element_tag.opce_principal("hi")).to eq("<opce-principal>hi</opce-principal>")
  end
end
