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

RSpec.describe EnvData::CustomDesignSeeder, :webmock do
  let(:safe_public_ip) { "93.184.216.34" }
  let(:seed_data) { Source::SeedData.new({}) }
  let(:base64_image) do
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wQACfsD/QqnFgAAAABJRU5ErkJggg=="
  end
  let(:base64_data_url) do
    "data:image/png;base64,#{base64_image}"
  end
  let(:png_stub) do
    stub_request(:get, "http://test.foobar.com/image.png")
      .to_return(
        status: 200,
        body: Rails.root.join("spec/fixtures/files/image.png").read
      )
  end
  let(:svg_stub) do
    stub_request(:get, "http://test.foobar.com/image.svg")
      .to_return(
        status: 200,
        body: Rails.root.join("spec/fixtures/files/icon_logo.svg").read
      )
  end
  subject(:seeder) { described_class.new(seed_data) }

  before do
    # CarrierWave remote URL downloading resolves hostnames with SsrfFilter.
    allow(Resolv).to receive(:getaddresses).with("test.foobar.com").and_return([safe_public_ip])

    png_stub
    svg_stub
  end

  context "when not provided" do
    it "does nothing" do
      seeder.seed!

      expect(DesignColor.all).to be_empty
      expect(CustomStyle.all).to be_empty
    end
  end

  # rubocop:disable Layout/LineLength
  context "when providing seed variables",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_DESIGN_PRIMARY__BUTTON__COLOR: "#571EFA",
            OPENPROJECT_SEED_DESIGN_ACCENT__COLOR: "#571EFA",
            OPENPROJECT_SEED_DESIGN_HEADER__BG__COLOR: "#FFFFFF",
            OPENPROJECT_SEED_DESIGN_MAIN__MENU__BG__COLOR: "#FFFFFF",
            OPENPROJECT_SEED_DESIGN_MAIN__MENU__BG__SELECTED__BACKGROUND: "#571EFA",
            OPENPROJECT_SEED_DESIGN_TOUCH__ICON: "http://test.foobar.com/image.png",
            OPENPROJECT_SEED_DESIGN_LOGO: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wQACfsD/QqnFgAAAABJRU5ErkJggg=="
          } do
    it "uses those variables" do
      reset(:seed_design)

      seeder.seed!

      expect(DesignColor.find_by(variable: "primary-button-color").hexcode).to eq("#571EFA")
      expect(DesignColor.find_by(variable: "accent-color").hexcode).to eq("#571EFA")
      expect(DesignColor.find_by(variable: "header-bg-color").hexcode).to eq("#FFFFFF")
      expect(DesignColor.find_by(variable: "main-menu-bg-color").hexcode).to eq("#FFFFFF")
      expect(DesignColor.find_by(variable: "main-menu-bg-selected-background").hexcode).to eq("#571EFA")

      RequestStore.clear!
      custom_style = CustomStyle.current
      expect(custom_style.logo.file).to be_present
      expect(custom_style.logo.file.content_type).to eq "image/png"

      expect(custom_style.touch_icon.file).to be_present
      expect(custom_style.touch_icon.file.content_type).to eq "image/png"
    end
  end

  context "when setting logo as svg",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_DESIGN_LOGO: "http://test.foobar.com/image.svg"
          } do
    it "sets the content type" do
      reset(:seed_design)

      seeder.seed!

      custom_style = CustomStyle.current

      expect(custom_style.logo.file).to be_present
      expect(custom_style.logo.file.content_type).to eq "image/svg+xml"
    end
  end

  context "when removing logo",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_DESIGN_LOGO: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wQACfsD/QqnFgAAAABJRU5ErkJggg=="
          } do
    it "uses those variables" do
      reset(:seed_design)

      custom_style = CustomStyle.new
      custom_style.favicon = File.open Rails.root.join("spec/fixtures/files/image.png").to_s
      custom_style.save!

      seeder.seed!

      custom_style.reload

      expect(custom_style.favicon.file).to be_nil
      expect(custom_style.logo.file).to be_present
      expect(custom_style.logo.file.content_type).to eq "image/png"
    end
  end

  context "when providing base64 without url",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_DESIGN_LOGO: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wQACfsD/QqnFgAAAABJRU5ErkJggg=="
          } do
    it "uses those variables" do
      reset(:seed_design)

      expect { seeder.seed! }.to raise_error /Expected data URL/
    end
  end
  # rubocop:enable Layout/LineLength

  context "when providing invalid color",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_DESIGN_PRIMARY__BUTTON__COLOR: "invalid!"
          } do
    it "uses those variables" do
      reset(:seed_design)

      expect { seeder.seed! }.to raise_error /Hex code is not a valid 6-digit hexadecimal color code./
    end
  end

  context "when providing export color",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_DESIGN_EXPORT__COVER__TEXT__COLOR: "#444444"
          } do
    it "uses those variables" do
      reset(:seed_design)

      seeder.seed!

      custom_style = CustomStyle.current
      expect(custom_style.export_cover_text_color).to eq "#444444"
    end
  end

  context "when not providing export color",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_DESIGN_PRIMARY__BUTTON__COLOR: "#571EFA"
          } do
    it "unsets that color" do
      reset(:seed_design)

      seeder.seed!

      custom_style = CustomStyle.current
      expect(custom_style.export_cover_text_color).to be_nil
    end
  end

  context "when providing not all colors",
          :settings_reset,
          with_env: {
            OPENPROJECT_SEED_DESIGN_PRIMARY__BUTTON__COLOR: "#571EFA",
            OPENPROJECT_SEED_DESIGN_ACCENT__COLOR: "#571EFA"
          } do
    it "uses those variables" do
      reset(:seed_design)

      DesignColor.create!(variable: "primary-button-color", hexcode: "#571EFA")
      DesignColor.create!(variable: "accent-color", hexcode: "#571EFA")
      DesignColor.create!(variable: "header-bg-color", hexcode: "#FFFFFF")
      DesignColor.create!(variable: "main-menu-bg-color", hexcode: "#FFFFFF")
      DesignColor.create!(variable: "main-menu-bg-selected-background", hexcode: "#571EFA")
      expect(DesignColor.count).to eq(5)

      seeder.seed!

      expect(DesignColor.count).to eq(2)
      expect(DesignColor.find_by(variable: "primary-button-color").hexcode).to eq("#571EFA")
      expect(DesignColor.find_by(variable: "accent-color").hexcode).to eq("#571EFA")
    end
  end
end
