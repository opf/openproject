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

RSpec.describe OpPrimer::DefinitionListComponent, type: :component do
  include ActionView::Helpers::TagHelper

  def render_component(**, &)
    render_inline(described_class.new(**), &)
  end

  context "with string content" do
    subject(:rendered_component) do
      render_component { "<dt>Term</dt><dd>Description</dd>".html_safe }
    end

    it "renders a definition list", :aggregate_failures do
      expect(rendered_component).to have_element :dl
      expect(rendered_component).to have_element :dt, text: "Term"
      expect(rendered_component).to have_element :dd, text: "Description"
    end
  end

  context "with tag: argument" do
    it "denies the tag" do
      allow(Rails.application.config.primer_view_components)
        .to receive(:raise_on_invalid_options).and_return(true)

      expect { render_component(tag: :ul) }.to raise_error ArgumentError
    end
  end

  context "with slots" do
    subject(:rendered_component) do
      render_component(classes: "my-list") do |list|
        list.with_item(classes: "my-item") do |item|
          item.with_term { "Text" }
          item.with_description(classes: "my-value") { "#FFFFFF" }
        end
        list.with_item do |item|
          item.with_term { "Background" }
          item.with_description { "#000000" }
          item.with_description { "fallback" }
        end
      end
    end

    it "renders items as div groups", :aggregate_failures do
      expect(rendered_component).to have_element :dl, class: "my-list" do |dl|
        expect(dl).to have_element :div, class: "my-item", count: 1 do |item|
          expect(item).to have_element :dt, text: "Text"
          expect(item).to have_element :dd, class: "my-value", text: "#FFFFFF"
        end
        expect(dl).to have_element :div, count: 2
        expect(dl).to have_element :dd, count: 3
      end
    end
  end

  context "with a description without content" do
    subject(:rendered_component) do
      render_component do |list|
        list.with_item do |item|
          item.with_term { "Text" }
          item.with_description(data: { contrast_value: "foreground" })
        end
      end
    end

    it "renders the empty dd for later filling" do
      expect(rendered_component).to have_element :dd, "data-contrast-value": "foreground", text: ""
    end
  end

  context "without items or content" do
    it "does not render" do
      expect(render_component).not_to have_element :dl
    end
  end
end
