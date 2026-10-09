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

require "spec_helper"

RSpec.describe Exports::PDF::Common::View do
  subject(:view) { described_class.new(:en) }

  describe "default_font" do
    context "without a custom style" do
      before do
        RequestStore.delete(:current_custom_style)
        allow(CustomStyle).to receive(:current).and_return(nil)
      end

      it "returns the latin default font family" do
        expect(described_class.default_font).to eq "NotoSans"
      end
    end

    context "with a valid custom style having export_font_regular" do
      let!(:custom_style) { create(:custom_style_with_export_font_regular) }

      after do
        # Reset memoized CustomStyle.current between examples
        RequestStore.delete(:current_custom_style)
      end

      it "returns the custom font family name" do
        expect(described_class.default_font).to eq described_class::CUSTOM_FONT_NAME
      end
    end
  end

  describe "valid_custom_font" do
    it "returns false when no CustomStyle is present" do
      allow(CustomStyle).to receive(:current).and_return(nil)
      expect(described_class.valid_custom_font?).to be false
    end

    it "returns true when a custom style with export_font_regular exists" do
      create(:custom_style_with_export_font_regular)
      expect(described_class.valid_custom_font?).to be true
    end
  end

  describe "fallback fonts" do
    it "builds symbol font file paths under public/fonts" do
      paths = view.fallback_symbol_fonts
      expect(paths).to all(be_a(Pathname))
      expect(paths.map(&:to_s)).to include(
        Rails.public_path.join("fonts/noto-emoji/NotoEmoji.ttf").to_s,
        Rails.public_path.join("fonts/noto-symbols/NotoSansSymbols2.ttf").to_s,
        Rails.public_path.join("fonts/noto-ancient/GoNotoAncient.ttf").to_s
      )
    end

    it "combines base font names and symbol font paths" do
      list = view.fallback_fonts
      # includes family names from FONT_SPEC[:fonts]
      expect(list).to include("GoNotoKurrent")
      # and absolute paths for the symbols
      expect(list).to include(*view.fallback_symbol_fonts)
    end
  end

  describe "document initialization" do
    it "creates a Prawn::Document with info and registers fonts" do
      doc = view.document

      # info
      expect(view.info[:Creator]).to eq OpenProject::Info.app_name
      expect(view.info[:CreationDate]).to respond_to(:to_time)

      # registered families include latin/mono/fonts groups
      expect(doc.font_families).to include("NotoSans", "SpaceMono", "GoNotoKurrent")

      # default font is set
      expect(doc.font.family).to eq described_class.default_font

      # fallback fonts set
      expect(doc.fallback_fonts).to eq(view.fallback_fonts)
    end

    it "uses the custom font as default when CustomStyle present" do
      create(:custom_style_with_export_font_regular)
      # New instance to pick up default font name
      custom_view = described_class.new(:en)
      doc = custom_view.document
      expect(doc.font.family).to eq described_class::CUSTOM_FONT_NAME
    end
  end

  describe "title accessor" do
    it "sets and gets the title in document info" do
      view.title = "My Report"
      expect(view.title).to eq "My Report"
      expect(view.info[:Title]).to eq "My Report"
    end
  end

  describe "apply_font" do
    before { view.document } # ensure fonts are registered

    it "applies name and style and returns the current font" do
      font = view.apply_font(name: "NotoSans", font_style: :bold)
      expect(font.basename).to end_with("-Bold")
      expect(view.document.font.family).to eq "NotoSans"
    end

    it "applies font size when provided" do
      view.apply_font(name: "NotoSans", size: 11)
      # Prawn keeps the size in the text state; API exposes current size via font_size
      expect(view.document.font_size).to eq 11
    end

    it "defaults name based on current font basename" do
      # First switch to SpaceMono so name inference uses it
      view.apply_font(name: "SpaceMono")
      inferred = view.apply_font(font_style: :italic)
      expect(inferred.basename).to match(/SpaceMono-.*Italic\z/)
    end
  end

  describe "font file resolution and family registration" do
    let(:doc) { Prawn::Document.new }

    it "resolves files for full and base variants with expected suffixes" do
      base_path = Rails.public_path.join("fonts/noto")
      full = view.resolved_font_files("NotoSans", base_path, variant: :full)
      base = view.resolved_font_files("NotoSans", base_path, variant: :base)

      expect(full[:normal].to_s).to end_with("NotoSans-Regular.ttf")
      expect(full[:italic].to_s).to end_with("NotoSans-Italic.ttf")
      expect(full[:bold].to_s).to end_with("NotoSans-Bold.ttf")
      expect(full[:bold_italic].to_s).to end_with("NotoSans-BoldItalic.ttf")

      expect(base[:normal].to_s).to end_with("NotoSans-Regular.ttf")
      expect(base[:italic].to_s).to end_with("NotoSans-Regular.ttf")
      expect(base[:bold].to_s).to end_with("NotoSans-Bold.ttf")
      expect(base[:bold_italic].to_s).to end_with("NotoSans-Bold.ttf")
    end

    it "registers a font family with style entries" do
      files = view.resolved_font_files("NotoSans", Rails.public_path.join("fonts/noto"), variant: :full)
      view.register_font_family!("TestFamily", files, doc)
      expect(doc.font_families["TestFamily"]).to include(
        normal: a_hash_including(:file, :font),
        italic: a_hash_including(:file, :font),
        bold: a_hash_including(:file, :font),
        bold_italic: a_hash_including(:file, :font)
      )
      expect(doc.font_families["TestFamily"][:bold][:file].to_s).to end_with("NotoSans-Bold.ttf")
      expect(doc.font_families["TestFamily"][:bold][:font]).to eq("TestFamily-Bold")
    end
  end

  describe "handle broken custom font storage" do
    it "falls back to default font without raising" do
      broken = instance_double(CustomStyle)
      allow(broken).to receive(:export_font_regular).and_raise("An error occurred while accessing the font file")
      allow(CustomStyle).to receive(:current).and_return(broken)

      expect { view.document }.not_to raise_error
      expect(view.document.font.family).to eq described_class.default_font
    end
  end
end
