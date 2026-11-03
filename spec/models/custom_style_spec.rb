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

RSpec.describe CustomStyle do
  describe "#current" do
    subject { described_class.current }

    context "when there is one in DB" do
      it "returns an instance" do
        described_class.create
        expect(subject).to be_a described_class
      end

      it "returns the same instance for subsequent calls" do
        described_class.create
        first_instance = described_class.current
        expect(subject).to be first_instance
      end
    end

    context "when there is none in DB" do
      before do
        RequestStore.delete(:current_custom_style)
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#logo_for" do
    context "for desktop logos" do
      it "returns the light logo in light mode" do
        custom_style = build(:custom_style_with_logo)

        expect(custom_style.logo_for(color_mode: :light)).to eq(custom_style.logo)
      end

      it "returns the light high contrast logo in light high contrast mode" do
        custom_style = build(:custom_style_with_logo_light_high_contrast)

        expect(custom_style.logo_for(color_mode: :light, high_contrast: true))
          .to eq(custom_style.logo_light_high_contrast)
      end

      it "falls back to the light logo when no light high contrast logo is uploaded" do
        custom_style = build(:custom_style_with_logo)

        expect(custom_style.logo_for(color_mode: :light, high_contrast: true)).to eq(custom_style.logo)
      end

      it "returns the dark logo in dark mode" do
        custom_style = build(:custom_style_with_logo_dark)

        expect(custom_style.logo_for(color_mode: :dark)).to eq(custom_style.logo_dark)
      end

      it "returns the dark logo in dark high contrast mode" do
        custom_style = build(:custom_style_with_logo_dark)

        expect(custom_style.logo_for(color_mode: :dark, high_contrast: true)).to eq(custom_style.logo_dark)
      end

      it "falls back to the light logo when no dark logo is uploaded" do
        custom_style = build(:custom_style_with_logo)

        expect(custom_style.logo_for(color_mode: :dark)).to eq(custom_style.logo)
      end
    end

    context "for mobile logos" do
      it "returns the mobile light high contrast logo in light high contrast mode" do
        custom_style = build(:custom_style_with_logo_mobile_light_high_contrast)

        expect(custom_style.logo_for(color_mode: :light, high_contrast: true, mobile: true))
          .to eq(custom_style.logo_mobile_light_high_contrast)
      end

      it "falls back to the mobile light logo when no mobile light high contrast logo is uploaded" do
        custom_style = build(:custom_style_with_logo_mobile)

        expect(custom_style.logo_for(color_mode: :light, high_contrast: true, mobile: true))
          .to eq(custom_style.logo_mobile)
      end

      it "returns the mobile dark logo in dark mode" do
        custom_style = build(:custom_style_with_logo_mobile_dark)

        expect(custom_style.logo_for(color_mode: :dark, mobile: true)).to eq(custom_style.logo_mobile_dark)
      end

      it "falls back to the mobile light logo when no mobile dark logo is uploaded" do
        custom_style = build(:custom_style_with_logo_mobile)

        expect(custom_style.logo_for(color_mode: :dark, mobile: true)).to eq(custom_style.logo_mobile)
      end
    end
  end

  shared_examples "removing an image from a custom style" do
    let(:image) { raise "define me!" }
    let(:custom_style) { create "custom_style_with_#{image}" }

    let!(:file_path) { custom_style.send(image).file.path }

    subject { custom_style.send :"remove_#{image}!" }

    it "deletes the file" do
      subject

      expect(File.exist?(file_path)).to be false
    end

    it "clears the file mount column" do
      subject

      expect(custom_style.reload.send(image).file).to be_nil
    end

    it "updates the model" do
      expect { subject }
        .to change(custom_style, :updated_at)
    end
  end

  describe "#remove_favicon" do
    it_behaves_like "removing an image from a custom style" do
      let(:image) { "favicon" }
    end
  end

  describe "#remove_touch_icon" do
    it_behaves_like "removing an image from a custom style" do
      let(:image) { "touch_icon" }
    end
  end

  describe "#remove_logo" do
    it_behaves_like "removing an image from a custom style" do
      let(:image) { "logo" }
    end
  end

  describe "#remove_logo_dark" do
    it_behaves_like "removing an image from a custom style" do
      let(:image) { "logo_dark" }
    end
  end

  describe "#remove_export_logo" do
    it_behaves_like "removing an image from a custom style" do
      let(:image) { "export_logo" }
    end
  end

  describe "#remove_export_cover" do
    it_behaves_like "removing an image from a custom style" do
      let(:image) { "export_cover" }
    end
  end

  describe "#remove_export_footer" do
    it_behaves_like "removing an image from a custom style" do
      let(:image) { "export_footer" }
    end
  end
end
