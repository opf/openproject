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

require "spec_helper"

RSpec.describe Pwa::OfflinePalette do
  subject(:palette) { described_class.new(header_color) }

  let(:light) { palette.light }
  let(:dark) { palette.dark }

  describe ".contrast" do
    it "computes the WCAG contrast ratio" do
      expect(described_class.contrast("#FFFFFF", "#1A67A3")).to be_within(0.05).of(5.98)
      expect(described_class.contrast("#1F2328", "#FAFAFA")).to be_within(0.05).of(15.14)
      expect(described_class.contrast("#FFFFFF", "#05002C")).to be_within(0.05).of(20.14)
    end
  end

  context "with a mid blue header" do
    let(:header_color) { "#1A67A3" }

    it "uses the header as light background with white ink" do
      expect(light).to have_attributes(background: "#1a67a3", ink: "#ffffff", divider: "rgba(255, 255, 255, 0.3)")
      expect(light.logo_tile).to be_nil
    end

    it "mixes the header into the dark canvas in dark mode" do
      expect(dark).to have_attributes(background: "#175687", ink: "#ffffff", logo_tile: nil)
    end
  end

  context "with a light header" do
    let(:header_color) { "#FAFAFA" }

    it "uses dark ink on the header in light mode" do
      expect(light).to have_attributes(background: "#fafafa", ink: "#1f2328")
    end

    it "uses the dark canvas and moves the header to a logo tile in dark mode" do
      expect(dark).to have_attributes(background: "#0d1117", ink: "#ffffff", logo_tile: "#fafafa")
    end

    it "uses the dark logo ink on the tile" do
      expect(dark.logo_ink).to eq("#1f2328")
    end
  end

  context "with a very dark header" do
    let(:header_color) { "#05002C" }

    it "uses white ink" do
      expect(light.ink).to eq("#ffffff")
    end
  end

  context "with a three digit header" do
    let(:header_color) { "#fff" }

    it "expands the shorthand" do
      expect(light.background).to eq("#ffffff")
    end
  end

  describe "primary button" do
    context "when the header contrasts with the primary green" do
      let(:header_color) { "#05002C" }

      it "keeps the primary tokens" do
        expect(light).to have_attributes(button_background: "#1f883d", button_foreground: "#ffffff")
        expect(dark).to have_attributes(button_background: "#238636", button_foreground: "#ffffff")
      end

      it "hovers with the primary hover tokens" do
        expect(light.button_hover).to eq("#1c8139")
        expect(dark.button_hover).to eq("#29903b")
      end
    end

    context "when the header is close to the primary green" do
      let(:header_color) { "#1F883D" }

      it "inverts to the ink on the page colour" do
        expect(light).to have_attributes(button_background: "#ffffff", button_foreground: "#1f883d")
      end

      it "hovers by mixing a tenth of the page colour into the ink" do
        expect(light.button_hover).to eq(described_class.mix("#ffffff", "#1f883d", 0.9))
      end
    end
  end
end
