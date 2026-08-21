# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe ColorsHelper do
  let(:model) { Data.define(:id).new(5) }

  describe "#hl_color_class" do
    it "returns the correct class name" do
      expect(helper.hl_color_class("foo_bar", model)).to eq("__hl_foo_bar_5")
    end

    it "accepts a bare id" do
      expect(helper.hl_color_class("foo_bar", 5)).to eq("__hl_foo_bar_5")
    end
  end

  describe "#hl_background_class" do
    it "pairs the usage class with the color class" do
      expect(helper.hl_background_class("foo_bar", model)).to eq("__hl_background __hl_foo_bar_5")
    end
  end

  describe "#hl_foreground_class" do
    it "pairs the usage class with the color class" do
      expect(helper.hl_foreground_class("foo_bar", model)).to eq("__hl_foreground __hl_foo_bar_5")
    end
  end

  describe "#hl_dot_class" do
    it "pairs the usage class with the color class" do
      expect(helper.hl_dot_class("foo_bar", model)).to eq("__hl_dot __hl_foo_bar_5")
    end
  end

  describe "#resource_color_css" do
    let(:red) { build_stubbed(:color, hexcode: "#FF0000") }

    it "emits the color as custom properties" do
      entry = Data.define(:id, :color).new(7, red)

      expect(helper.resource_color_css("status", [entry]))
        .to eq(".__hl_status_7 { --hl-color: #FF0000; --hl-perceived-lightness: 0.2126 }")
    end

    it "takes Color records as their own color" do
      expect(helper.resource_color_css("color", [red]))
        .to eq(".__hl_color_#{red.id} { --hl-color: #FF0000; --hl-perceived-lightness: 0.2126 }")
    end

    it "only suppresses the dot for entries without a color" do
      entry = Data.define(:id, :color).new(7, nil)

      expect(helper.resource_color_css("status", [entry]))
        .to eq(".__hl_status_7.__hl_dot::before { display: none }")
    end
  end

  describe "#icon_for_color" do
    context "with nil color" do
      it "renders nothing" do
        expect(helper.icon_for_color(nil)).to be_blank
      end
    end

    context "with valid color" do
      it "renders a color preview" do
        expect(helper.icon_for_color(Color.new(hexcode: "#ff00ff"))).to be_html_eql %{
          <span class="color--preview " style="background-color: #FF00FF;border-color: #80008050"> </span>
        }.squish
      end
    end

    context "with invalid color (invalid hexcode)" do
      it "renders nothing" do
        expect(helper.icon_for_color(Color.new(hexcode: "#ffXXff"))).to be_blank
      end
    end
  end
end
