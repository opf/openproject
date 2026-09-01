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

  describe ".desktop_logo_present?" do
    subject { helper.desktop_logo_present? }

    context "with only a dark desktop logo" do
      let(:current_theme) { build(:custom_style_with_logo_dark) }

      it { is_expected.to be true }
    end

    context "without a desktop logo" do
      let(:current_theme) { build_stubbed(:custom_style) }

      it { is_expected.to be false }
    end
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

  describe ".custom_logo_uploads" do
    let(:style) { create(:custom_style_with_logo) }

    it "returns the legacy and variant paths" do
      uploads = helper.custom_logo_uploads(style).index_by { |upload| upload[:field] }

      expect(uploads.dig(:logo, :source))
        .to eq(custom_style_logo_path(digest: style.digest, filename: style.logo_identifier))
      expect(uploads.dig(:logo, :delete_path)).to eq(custom_style_logo_delete_path)
      expect(uploads.dig(:logo_dark, :source)).to be_nil
      expect(uploads.dig(:logo_dark, :delete_path))
        .to eq(custom_style_logo_variant_delete_path(variant: :logo_dark))
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
