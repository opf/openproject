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

RSpec.describe CustomStylesHelper do
  let(:current_theme) { nil }
  let(:bim_edition?) { false }

  before do
    allow(CustomStyle).to receive(:current).and_return(current_theme)
    allow(OpenProject::Configuration).to receive(:bim?).and_return(bim_edition?)
  end

  describe ".apply_custom_styles?" do
    subject { helper.apply_custom_styles? }

    context "no CustomStyle present" do
      it "is falsey" do
        expect(subject).to be_falsey
      end
    end

    context "CustomStyle present" do
      let(:current_theme) { build_stubbed(:custom_style) }

      context "without EE", with_ee: false do
        context "no BIM edition" do
          it "is falsey" do
            expect(subject).to be_falsey
          end
        end

        context "BIM edition" do
          let(:bim_edition?) { true }

          it "is truthy" do
            expect(subject).to be_truthy
          end
        end
      end

      context "with EE", with_ee: %i[define_custom_style] do
        context "no BIM edition" do
          it "is truthy" do
            expect(subject).to be_truthy
          end
        end

        context "BIM edition" do
          let(:bim_edition?) { true }

          it "is truthy" do
            expect(subject).to be_truthy
          end
        end
      end
    end
  end

  shared_examples("apply when ee present") do
    context "no CustomStyle present" do
      it "is falsey" do
        expect(subject).to be_falsey
      end
    end

    context "CustomStyle present" do
      let(:current_theme) { build_stubbed(:custom_style) }

      before do
        allow(current_theme).to receive(:favicon).and_return(true)
        allow(current_theme).to receive(:touch_icon).and_return(true)
      end

      context "without EE", with_ee: false do
        it "is falsey" do
          expect(subject).to be_falsey
        end
      end

      context "with EE", with_ee: %i[define_custom_style] do
        it "is truthy" do
          expect(subject).to be_truthy
        end
      end
    end
  end

  describe ".apply_custom_favicon?" do
    subject { helper.apply_custom_favicon? }

    it_behaves_like "apply when ee present"
  end

  describe ".apply_custom_touch_icon?" do
    subject { helper.apply_custom_touch_icon? }

    it_behaves_like "apply when ee present"
  end

  describe ".mobile_logo_present?" do
    subject { helper.mobile_logo_present? }

    context "with only a light high contrast mobile logo" do
      let(:current_theme) { build(:custom_style_with_logo_mobile_light_high_contrast) }

      it { is_expected.to be true }
    end

    context "without a mobile logo" do
      let(:current_theme) { build_stubbed(:custom_style) }

      it { is_expected.to be false }
    end
  end

  describe ".mobile_logo_modes" do
    context "without a custom style" do
      it "keeps the default mobile logo available in every mode" do
        expect(helper.mobile_logo_modes).to eq(%i[light light_high_contrast dark])
      end
    end

    context "with only a built-in theme logo" do
      let(:current_theme) { build_stubbed(:custom_style, theme_logo: "logo_openproject.png") }

      it "keeps the default mobile logo available in every mode" do
        expect(helper.mobile_logo_modes).to eq(%i[light light_high_contrast dark])
      end
    end

    context "with only a dark mobile logo" do
      let(:current_theme) { build(:custom_style_with_logo_mobile_dark) }

      it "keeps the default mobile logo where the desktop uses its default" do
        expect(helper.mobile_logo_modes).to eq(%i[light light_high_contrast dark])
      end
    end

    context "with only a dark desktop logo" do
      let(:current_theme) { build(:custom_style_with_logo_dark) }

      it "hides the mobile logo only where the custom desktop logo is used" do
        expect(helper.mobile_logo_modes).to eq(%i[light light_high_contrast])
      end
    end
  end

  describe ".resolved_logo_urls" do
    subject(:logo_urls) { helper.resolved_logo_urls }

    context "without custom styles" do
      it "returns distinct default mobile logos" do
        expect(logo_urls[:mobile]).to eq(
          light: helper.asset_path("icon_logo.svg"),
          white: helper.asset_path("icon_logo_white.svg"),
          light_high_contrast: helper.asset_path("icon_logo.svg"),
          dark: helper.asset_path("icon_logo_white.svg")
        )
      end
    end

    context "with a custom mobile light logo", with_ee: %i[define_custom_style] do
      let(:current_theme) { create(:custom_style_with_logo_mobile) }

      it "uses it for the light mobile header" do
        path = custom_style_logo_path(
          digest: current_theme.digest,
          filename: current_theme.logo_mobile_identifier,
          field: :logo_mobile
        )

        expect(logo_urls.dig(:mobile, :white)).to eq(path)
      end

      it "uses it for every desktop mode when no desktop logo is uploaded" do
        path = custom_style_logo_path(
          digest: current_theme.digest,
          filename: current_theme.logo_mobile_identifier,
          field: :logo_mobile
        )

        expect(logo_urls[:desktop]).to eq(light: path, light_high_contrast: path, dark: path)
      end
    end

    context "with only a custom mobile high-contrast logo", with_ee: %i[define_custom_style] do
      let(:current_theme) { create(:custom_style_with_logo_mobile_light_high_contrast) }

      it "uses it for desktop high contrast and keeps the other desktop defaults" do
        path = custom_style_logo_path(
          digest: current_theme.digest,
          filename: current_theme.logo_mobile_light_high_contrast_identifier,
          field: :logo_mobile_light_high_contrast
        )

        expect(logo_urls[:desktop]).to eq(
          light: helper.asset_path("logo_openproject_white_big.png"),
          light_high_contrast: path,
          dark: helper.asset_path("logo_openproject_white_big.png")
        )
      end
    end

    context "with a desktop light logo and a mobile high-contrast logo", with_ee: %i[define_custom_style] do
      let(:current_theme) do
        create(
          :custom_style_with_logo,
          logo_mobile_light_high_contrast: Rack::Test::UploadedFile.new(
            Rails.root.join("spec/support/custom_styles/logos/logo_image.png")
          )
        )
      end

      it "uses the mobile logo for desktop high contrast" do
        desktop_path = custom_style_logo_path(
          digest: current_theme.digest,
          filename: current_theme.logo_identifier,
          field: :logo
        )
        high_contrast_path = custom_style_logo_path(
          digest: current_theme.digest,
          filename: current_theme.logo_mobile_light_high_contrast_identifier,
          field: :logo_mobile_light_high_contrast
        )

        expect(logo_urls[:desktop]).to eq(
          light: desktop_path,
          light_high_contrast: high_contrast_path,
          dark: desktop_path
        )
      end
    end

    context "with only a custom mobile dark logo", with_ee: %i[define_custom_style] do
      let(:current_theme) { create(:custom_style_with_logo_mobile_dark) }

      it "uses it for desktop dark and keeps the other desktop defaults" do
        path = custom_style_logo_path(
          digest: current_theme.digest,
          filename: current_theme.logo_mobile_dark_identifier,
          field: :logo_mobile_dark
        )

        expect(logo_urls[:desktop]).to eq(
          light: helper.asset_path("logo_openproject_white_big.png"),
          light_high_contrast: helper.asset_path("logo_openproject.png"),
          dark: path
        )
      end
    end

    context "with only a custom dark logo", with_ee: %i[define_custom_style] do
      let(:current_theme) { create(:custom_style_with_logo_dark) }

      it "uses the custom dark URL and keeps the default light URL" do
        path = custom_style_logo_path(
          digest: current_theme.digest,
          filename: current_theme.logo_dark_identifier,
          field: :logo_dark
        )

        expect(logo_urls.dig(:desktop, :dark)).to eq(path)
        expect(logo_urls.dig(:desktop, :light)).to eq(helper.asset_path("logo_openproject_white_big.png"))
      end
    end

    context "with a theme logo and a custom dark logo", with_ee: %i[define_custom_style] do
      let(:current_theme) { create(:custom_style_with_logo_dark, theme_logo: "icon_logo.svg") }

      it "prefers the custom dark logo and keeps the theme logo for light mode" do
        path = custom_style_logo_path(
          digest: current_theme.digest,
          filename: current_theme.logo_dark_identifier,
          field: :logo_dark
        )

        expect(logo_urls[:desktop]).to eq(
          light: helper.asset_path(current_theme.theme_logo),
          light_high_contrast: helper.asset_path("logo_openproject.png"),
          dark: path
        )
      end
    end

    context "with a theme logo and Russian locale", with_ee: %i[define_custom_style] do
      let(:current_theme) { create(:custom_style, theme_logo: "logo_openproject.png") }

      it "substitutes the Russian variant for the theme logo" do
        I18n.with_locale(:ru) do
          expect(logo_urls.dig(:desktop, :light)).to eq(helper.asset_path("logo-black-bg-ua.png"))
          expect(logo_urls.dig(:desktop, :dark)).to eq(helper.asset_path("logo-black-bg-ua.png"))
          expect(logo_urls.dig(:desktop, :light_high_contrast)).to eq(helper.asset_path("logo-black-bg-ua.png"))
        end
      end
    end

    context "with a custom light logo", with_ee: %i[define_custom_style] do
      let(:current_theme) { create(:custom_style_with_logo) }

      it "uses it for every desktop mode" do
        path = custom_style_logo_path(
          digest: current_theme.digest,
          filename: current_theme.logo_identifier,
          field: :logo
        )

        expect(logo_urls[:desktop]).to eq(
          light: path,
          light_high_contrast: path,
          dark: path
        )
      end
    end
  end

  describe ".custom_logo_uploads" do
    let(:style) { create(:custom_style_with_logo) }

    it "returns the logo paths" do
      uploads = helper.custom_logo_uploads(style).index_by { |upload| upload[:field] }

      expect(uploads.dig(:logo, :source))
        .to eq(custom_style_logo_path(digest: style.digest, field: :logo, filename: style.logo_identifier))
      expect(uploads.dig(:logo, :delete_path)).to eq(custom_style_logo_delete_path(field: :logo))
      expect(uploads.dig(:logo_dark, :source)).to be_nil
      expect(uploads.dig(:logo_dark, :delete_path))
        .to eq(custom_style_logo_delete_path(field: :logo_dark))
    end
  end

  describe ".export_fonts_fields" do
    let(:style) { create(:custom_style_with_export_font_regular) }

    it "returns entries for all four variants with correct delete paths and filename" do
      fields = helper.export_fonts_fields(style)
      expect(fields.size).to eq(4)

      names = fields.pluck(:field)
      expect(names).to contain_exactly(:export_font_regular, :export_font_bold, :export_font_italic, :export_font_bold_italic)

      regular = fields.find { |f| f[:field] == :export_font_regular }
      expect(regular[:present]).to be_truthy
      expect(regular[:filename]).to be_present
      expect(regular[:delete_path]).to eq(custom_style_export_font_regular_delete_path)

      bold = fields.find { |f| f[:field] == :export_font_bold }
      expect(bold[:present]).to be_falsey
      expect(bold[:filename]).to be_nil
      expect(bold[:delete_path]).to eq(custom_style_export_font_bold_delete_path)

      italic = fields.find { |f| f[:field] == :export_font_italic }
      expect(italic[:delete_path]).to eq(custom_style_export_font_italic_delete_path)

      bold_italic = fields.find { |f| f[:field] == :export_font_bold_italic }
      expect(bold_italic[:delete_path]).to eq(custom_style_export_font_bold_italic_delete_path)
    end
  end
end
