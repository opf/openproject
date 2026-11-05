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

RSpec.describe OpPrimer::AttributesGroupComponent, type: :component do
  it "renders the title" do
    render_inline(described_class.new) do |component|
      component.with_header(title: "A Title")

      component.with_attribute(key: "Attribute Key 1") { "Attribute Value 1" }
      component.with_attribute(key: "Attribute Key 2") { "Attribute Value 2" }
    end

    aggregate_failures "group header" do
      expect(page).to have_css(".AttributesGroup")
      expect(page).to have_css("h3", text: "A Title")
    end

    aggregate_failures "attribute key value" do
      expect(page).to have_css(".AttributesGroupItem")
      expect(page).to have_css(".AttributesGroupItem-key", text: "Attribute Key 1") &
       have_css(".AttributesGroupItem-value", text: "Attribute Value 1")
      expect(page).to have_css(".AttributesGroupItem-key", text: "Attribute Key 2") &
       have_css(".AttributesGroupItem-value", text: "Attribute Value 2")
    end
  end

  it "groups each term with its description in a definition list" do
    render_inline(described_class.new) do |component|
      component.with_header(title: "Details")
      component.with_attribute(key: "First") { "One" }
      component.with_attribute(key: "Second") { "Two" }
    end

    expect(page).to have_css(".AttributesGroup > .Subhead", text: "Details")
    expect(page).to have_css("dl.AttributesGroupWrap > .AttributesGroupItem", count: 2)

    list = page.find("dl.AttributesGroupWrap")
    expect(list).to have_no_css("h3")
    pairs = list.all(".AttributesGroupItem").map do |item|
      [item.find("dt").text, item.find("dd").text]
    end
    expect(pairs).to eq([["First", "One"], ["Second", "Two"]])
  end

  it "renders content when provided" do
    render_inline(described_class.new) do |component|
      component.with_header(title: "A Title")

      "Raw Content"
    end

    expect(page).to have_no_text("Raw Content")

    aggregate_failures "group header" do
      expect(page).to have_css(".AttributesGroup")
      expect(page).to have_css("h3", text: "A Title")
    end
  end

  it "keeps HTML block content" do
    render_inline(described_class.new) do |component|
      component.with_attribute(key: "Link") { "<a href=\"/docs\">Docs</a>".html_safe }
    end

    expect(page).to have_element(:dd, class: "AttributesGroupItem-value") do |dd|
      expect(dd).to have_link("Docs", href: "/docs")
    end
  end

  it "renders a header without attributes" do
    render_inline(described_class.new) do |component|
      component.with_header(title: "Empty")
    end

    expect(page).to have_element(:h3, text: "Empty")
    expect(page).to have_no_element(:dt)
  end

  it "adds the tabular scheme" do
    render_inline(described_class.new(scheme: :tabular)) do |component|
      component.with_attribute(key: "Key") { "Value" }
    end

    expect(page).to have_element(:div, class: %w[AttributesGroup AttributesGroup--tabular])
  end

  it "mutes labels independently of the scheme", :aggregate_failures do
    render_inline(described_class.new(label_color: :muted)) do |component|
      component.with_attribute(key: "Key") { "Value" }
    end

    expect(page).to have_element(:div, class: "AttributesGroup--mutedLabels")
    expect(page).to have_no_element(:div, class: "AttributesGroup--tabular")
  end

  it "uses the default scheme and label color without options", :aggregate_failures do
    render_inline(described_class.new) do |component|
      component.with_attribute(key: "Key") { "Value" }
    end

    expect(page).to have_no_element(:div, class: "AttributesGroup--tabular")
    expect(page).to have_no_element(:div, class: "AttributesGroup--mutedLabels")
  end

  it "rejects unknown options outside production" do
    expect { render_inline(described_class.new(scheme: :bogus)) }
      .to raise_error(Primer::FetchOrFallbackHelper::InvalidValueError)
  end

  it "renders several values for one attribute" do
    render_inline(described_class.new) do |component|
      component.with_attribute(key: "Filters") do |attribute|
        attribute.with_value { "Status is open" }
        attribute.with_value { "Assignee is me" }
      end
    end

    expect(page).to have_element(:div, class: "AttributesGroupItem") do |item|
      expect(item).to have_element(:dt, text: "Filters")
      expect(item).to have_element(:dd, text: "Status is open")
      expect(item).to have_element(:dd, text: "Assignee is me")
    end
  end

  it "rejects block content combined with values" do
    expect do
      render_inline(described_class.new) do |component|
        component.with_attribute(key: "Filters") do |attribute|
          attribute.with_value { "Status is open" }
          "Assignee is me"
        end
      end
    end.to raise_error(ArgumentError)
  end
end
