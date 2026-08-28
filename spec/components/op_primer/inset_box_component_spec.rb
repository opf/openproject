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

RSpec.describe OpPrimer::InsetBoxComponent, type: :component do
  def render_component(**args)
    render_inline(described_class.new(**args))
  end

  context "with defaults" do
    subject(:rendered) { render_component }

    it "renders with default inset styles" do
      expect(rendered).to have_css(".color-bg-inset.p-3.rounded-2")
    end

    it "renders with border by default" do
      expect(rendered).to have_css(".border")
      expect(rendered).to have_no_css(".border-0")
    end
  end

  context "when border is false" do
    subject(:rendered) { render_component(border: false) }

    it "renders border-0 instead of border" do
      expect(rendered).to have_css(".border-0")
      expect(rendered).to have_no_css(".border")
    end
  end

  context "with a scheme" do
    it "keeps the inset background by default" do
      expect(render_component).to have_css(".color-bg-inset")
    end

    it "renders the info scheme in accent colors" do
      rendered = render_component(scheme: :info)

      expect(rendered).to have_css(".color-bg-accent.color-border-accent")
    end

    it "renders the warning scheme in attention colors" do
      rendered = render_component(scheme: :warning)

      expect(rendered).to have_css(".color-bg-attention.color-border-attention")
    end

    it "renders the danger scheme in danger colors" do
      rendered = render_component(scheme: :danger)

      expect(rendered).to have_css(".color-bg-danger.color-border-danger")
    end

    it "renders the success scheme in success colors" do
      rendered = render_component(scheme: :success)

      expect(rendered).to have_css(".color-bg-success.color-border-success")
    end
  end

  context "when custom classes are passed" do
    subject(:rendered) { render_component(classes: "my-extra-class") }

    it "applies custom classes" do
      expect(rendered).to have_css(".my-extra-class")
    end
  end

  context "with a title" do
    it "renders the title in a heading at body size" do
      rendered = render_inline(described_class.new) do |box|
        box.with_title { "Reuse mode" }
      end

      expect(rendered).to have_css("h3.f5.text-semibold", text: "Reuse mode")
      expect(rendered).to have_no_css(".octicon")
    end

    it "renders the title icon in front of the title" do
      rendered = render_inline(described_class.new) do |box|
        box.with_title_icon(icon: :link)
        box.with_title { "Linked mode" }
      end

      expect(rendered).to have_css(".octicon-link + h3", text: "Linked mode")
    end

    it "honours a custom heading tag" do
      rendered = render_inline(described_class.new) do |box|
        box.with_title(tag: :h2) { "Dependents" }
      end

      expect(rendered).to have_css("h2", text: "Dependents")
    end
  end

  context "with actions" do
    it "renders several action buttons after the content" do
      rendered = render_inline(described_class.new) do |box|
        box.with_action_button { "Change source" }
        box.with_action_button(scheme: :primary) { "Switch mode" }
        "Some content"
      end

      expect(rendered).to have_button("Change source")
      expect(rendered).to have_button("Switch mode")
      expect(rendered.text.index("Some content")).to be < rendered.text.index("Change source")
    end

    it "renders an action menu" do
      rendered = render_inline(described_class.new) do |box|
        box.with_action_menu do |menu|
          menu.with_show_button { "Actions" }
          menu.with_item(label: "Unlink")
        end
      end

      expect(rendered).to have_button("Actions")
      expect(rendered).to have_css("action-menu")
      expect(rendered).to have_text("Unlink")
    end

    it "renders no action container without actions" do
      rendered = render_inline(described_class.new) { "Only content" }

      expect(rendered).to have_no_css(".d-flex")
    end
  end
end
