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

RSpec.describe OpPrimer::ListComponent, type: :component do
  include ActionView::Helpers::TagHelper

  def render_component(**, &)
    render_inline(described_class.new(**), &)
  end

  context "with string content" do
    let(:args) { {} }

    subject(:rendered_component) do
      render_component(**args) do
        "<li>List item</lI>".html_safe
      end
    end

    context "with default :tag (unordered list)" do
      it "renders list" do
        expect(rendered_component).to have_element :ul, class: "list-style-none"
      end

      it "renders list item" do
        expect(rendered_component).to have_element :li, text: "List item"
      end
    end

    context "with tag: :ol (ordered list)" do
      let(:args) { { tag: :ol } }

      it "renders list" do
        expect(rendered_component).to have_element :ol, class: "list-style-none"
      end

      it "renders list item" do
        expect(rendered_component).to have_element :li, text: "List item"
      end
    end

    context "with invalid tag:" do
      let(:args) { { tag: "not-a-list-tag" } }

      it "raises an InvalidValueError" do
        expect { rendered_component }.to raise_error Primer::FetchOrFallbackHelper::InvalidValueError
      end
    end
  end

  context "with helper tags" do
    subject(:rendered_component) do
      render_component do
        content_tag(:li, "List item")
      end
    end

    it "renders list" do
      expect(rendered_component).to have_element :ul, class: "list-style-none"
    end

    it "renders list item" do
      expect(rendered_component).to have_element :li, text: "List item"
    end
  end

  context "with slots" do
    subject(:rendered_component) do
      render_component do |list|
        list.with_item do
          "List item 1"
        end

        list.with_divider

        list.with_item do
          "List item 2"
        end
      end
    end

    it "renders list" do
      expect(rendered_component).to have_element :ul, class: "list-style-none"
    end

    it "renders list items" do
      expect(rendered_component).to have_list_item count: 2
      expect(rendered_component).to have_list_item position: 1, text: "List item 1"
      expect(rendered_component).to have_list_item position: 3, text: "List item 2"
    end
  end
end
