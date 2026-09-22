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

RSpec.describe OpenProject::StrikezoneFrank::Branding do
  describe ".apply!" do
    it "renames the stock OpenProject app title to Strikezone" do
      Setting.app_title = "OpenProject"
      Setting.software_name = "OpenProject"

      described_class.apply!

      expect(Setting.app_title).to eq("Strikezone")
      expect(Setting.software_name).to eq("Strikezone")
    end

    it "does not overwrite a custom admin-chosen title" do
      Setting.app_title = "Strikezone PM"
      Setting.software_name = "Strikezone PM"

      described_class.apply!

      expect(Setting.app_title).to eq("Strikezone PM")
      expect(Setting.software_name).to eq("Strikezone PM")
    end
  end

  describe ".color_theme" do
    it "maps brand-book colours onto OpenProject Design tokens" do
      theme = described_class.color_theme

      expect(theme[:theme]).to eq("Strikezone")
      expect(theme[:colors]).to include(
        "primary-button-color" => "#DF5301",
        "accent-color" => "#ED6718",
        "header-bg-color" => "#101010",
        "main-menu-bg-color" => "#FFFFFF",
        "main-menu-bg-selected-background" => "#FFF3EC"
      )
      expect(theme[:logo]).to eq("strikezone_frank/logo-white.svg")
    end
  end

  describe ".theme_css_variables" do
    subject(:variables) { described_class.theme_css_variables }

    it "derives hover tokens the same way DesignColor / inline_css does" do
      primary = described_class::Swatch.new("#DF5301")
      accent = described_class::Swatch.new("#ED6718")

      expect(variables["primary-button-color--major1"]).to eq(primary.darken(0.18))
      expect(variables["accent-color--major1"]).to eq(accent.darken(0.2))
      expect(variables["primary-button-color--major1"]).not_to eq("#197032")
      expect(variables["accent-color--major1"]).not_to eq("#155282")
    end

    it "sets Baloo Bhaina 2 and Neutral 700 body colour" do
      expect(variables["body-font-family"]).to include("Baloo Bhaina 2")
      expect(variables["body-font-color"]).to eq("#1F1F1F")
    end
  end

  describe ".inject_theme_tokens?" do
    it "injects plugin tokens when Design is not EE-overridden" do
      expect(described_class.inject_theme_tokens?).to be(true)
    end

    context "with EE Design colours already saved", with_ee: %i[define_custom_style] do
      it "lets Administration > Design win" do
        create(:"design_color_primary-button-color")

        expect(described_class.inject_theme_tokens?).to be(false)
      end
    end
  end
end
