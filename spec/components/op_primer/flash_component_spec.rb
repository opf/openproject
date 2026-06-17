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

RSpec.describe OpPrimer::FlashComponent, type: :component do
  describe "#render" do
    def render_component(content, ...)
      render_inline(described_class.new(...).with_content(content))
    end

    subject(:rendered_component) { render_component(content) }

    context "with content" do
      let(:content) { "Flash Text" }

      it "renders an x-banner" do
        expect(rendered_component).to have_element "x-banner"
      end

      it "renders the banner text" do
        expect(rendered_component).to have_css ".Banner-message .Banner-title", text: "Flash Text"
      end

      it "marks the flash for polite announcement" do
        expect(rendered_component).to have_css '[data-announcement="Flash Text"][data-politeness="polite"]'
      end
    end

    context "with danger scheme" do
      let(:content) { "Flash Error" }

      subject(:rendered_component) { render_component(content, scheme: :danger) }

      it "marks the flash for assertive announcement" do
        expect(rendered_component).to have_css '[data-announcement="Flash Error"][data-politeness="assertive"]'
      end

      context "with description" do
        subject(:rendered_component) do
          render_component(
            content,
            scheme: :danger,
            description: "There was a problem with the following field:<br>Name can't be blank.".html_safe
          )
        end

        it "includes the description in the announcement" do
          expect(rendered_component).to have_css(
            "[data-announcement=\"Flash Error There was a problem with the following field: Name can't be blank.\"]"
          )
        end
      end
    end

    context "with success scheme" do
      let(:content) { "Flash Text" }

      subject(:rendered_component) { render_component(content, scheme: :success) }

      it "marks the flash for autohide" do
        expect(rendered_component).to have_css '[data-autohide="true"]'
      end

      context "with disabled dismissing" do
        subject(:rendered_component) { render_component(content, scheme: :success, dismiss_scheme: :none) }

        it "does not mark the flash for autohide" do
          expect(rendered_component).to have_css '[data-autohide="false"]'
        end
      end
    end

    context "with blank content" do
      let(:content) { " " }

      it "renders nothing" do
        expect(rendered_component.to_s).to be_empty
      end

      it "does not render an x-banner" do
        expect(rendered_component).to have_no_element "x-banner"
      end

      it "does not render the banner text" do
        expect(rendered_component).to have_no_css ".Banner-message .Banner-title"
      end
    end
  end

  describe "#render_as_turbo_stream" do
    def render_component_as_turbo_stream(content, ...)
      component_class = described_class
      render_in_view_context do
        component_class.new(...)
          .with_content(content)
          .render_as_turbo_stream(view_context: self, action: :flash)
      end
    end

    subject(:rendered_component) { render_component_as_turbo_stream(content) }

    let(:rendered_template) { Nokogiri(rendered_component.to_s).css("turbo-stream template").first&.inner_html&.strip }

    context "with content" do
      let(:content) { "Flash Text" }

      it "renders a template" do
        expect(rendered_template).not_to be_blank
      end

      it "renders an x-banner within the template" do
        expect(rendered_template).to have_element "x-banner"
      end

      it "renders the banner text within the template" do
        expect(rendered_template).to have_css ".Banner-message .Banner-title", text: "Flash Text"
      end

      it "renders announcement data within the template" do
        expect(rendered_template).to have_css '[data-announcement="Flash Text"][data-politeness="polite"]'
      end
    end

    context "with HTML content" do
      let(:content) { "First line<br />Second line<ul><li>First item</li><li>Second item</li></ul>".html_safe }

      it "provides a text-only live region message" do
        component = described_class.new.with_content(content)

        expect(component.live_region_message).to eq "First line Second line First item Second item"
      end
    end

    context "with blank content" do
      let(:content) { " " }

      it "renders nothing" do
        expect(rendered_component.to_s).to be_empty
      end

      it "does not render a template" do
        expect(rendered_template).to be_nil
      end
    end
  end
end
