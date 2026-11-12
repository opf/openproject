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

RSpec.describe Exports::PDF::Common::Attachments do
  let(:helper) do
    obj = Object.new
    obj.extend(described_class)
    obj.define_singleton_method(:api_url_helpers) { API::V3::Utilities::PathHelper::ApiV3Path }
    obj
  end

  # Registers the crafted file with the helper so `delete_all_resized_images` cleans it up.
  def crafted_webp(body)
    path = helper.temp_image_file(".webp")
    File.binwrite(path, "RIFF".b + [body.bytesize].pack("V") + body)
    path
  end

  def anmf_chunk(payload) = "ANMF".b + [payload.bytesize].pack("V") + payload

  def vp8x_chunk(flags) = "VP8X".b + [10].pack("V") + flags.chr + ("\0".b * 9)

  # 16 bytes of ANMF frame metadata followed by a bitstream chunk id
  def anmf_payload(bitstream_id) = ("\0".b * 16) + bitstream_id.b + ("\0".b * 4)

  describe "#convert_webp_to_png" do
    after { helper.delete_all_resized_images }

    it "converts the single-frame source instead of the original animation" do
      animated_webp = Rails.root.join("spec/fixtures/files/animated.webp").to_s
      allow(MiniMagick::Image).to receive(:open).and_call_original

      helper.convert_webp_to_png(animated_webp)

      expect(MiniMagick::Image).not_to have_received(:open).with(animated_webp)
    end

    it "keeps the transparency of an animation whose first frame carries alpha" do
      alpha_webp = Rails.root.join("spec/fixtures/files/animated_alpha.webp").to_s

      result = MiniMagick::Image.open(helper.convert_webp_to_png(alpha_webp))

      expect([result.width, result.height]).to eq([60, 40])
      expect(result["%[channels]"]).to include("a")
    end

    context "when the file is an animation without a usable first frame" do
      let(:unreadable_animation) { crafted_webp("WEBP".b + anmf_chunk(anmf_payload("JUNK"))) }

      before do
        allow(Rails.logger).to receive(:error)
        allow(MiniMagick::Image).to receive(:open)
      end

      it "returns nil" do
        expect(helper.convert_webp_to_png(unreadable_animation)).to be_nil
      end

      # Handing the animation to ImageMagick would expand every frame into its pixel cache
      it "never opens the animation" do
        helper.convert_webp_to_png(unreadable_animation)
        expect(MiniMagick::Image).not_to have_received(:open)
      end
    end
  end

  describe "#webp_single_frame_source" do
    let(:animated_webp) { Rails.root.join("spec/fixtures/files/animated.webp").to_s }
    let(:static_webp)   { Rails.root.join("spec/fixtures/files/image.webp").to_s }
    let(:non_webp)      { Rails.root.join("spec/fixtures/files/image.png").to_s }

    after { helper.delete_all_resized_images }

    context "with an animated WebP" do
      it "does not return the animation itself" do
        expect(helper.webp_single_frame_source(animated_webp)).not_to eq(animated_webp)
      end

      it "returns a path to an existing file" do
        result = helper.webp_single_frame_source(animated_webp)
        expect(File.exist?(result)).to be true
      end

      it "returns a file with image/webp MIME type" do
        result = helper.webp_single_frame_source(animated_webp)
        expect(Marcel::MimeType.for(Pathname.new(result))).to eq("image/webp")
      end

      it "returns a single-frame WebP" do
        result = helper.webp_single_frame_source(animated_webp)
        expect(MiniMagick::Image.open(result).frames.count).to eq(1)
      end

      it "returns a file with a valid RIFF/WEBP container header" do
        result = helper.webp_single_frame_source(animated_webp)
        data = File.binread(result)
        expect(data[0, 4]).to eq("RIFF".b)
        expect(data[8, 4]).to eq("WEBP".b)
      end
    end

    context "with an animation whose first frame carries alpha" do
      let(:alpha_webp) { Rails.root.join("spec/fixtures/files/animated_alpha.webp").to_s }

      it "returns a single-frame WebP of the frame's size" do
        result = MiniMagick::Image.open(helper.webp_single_frame_source(alpha_webp))

        expect(result.frames.count).to eq(1)
        expect([result.width, result.height]).to eq([60, 40])
      end

      # An ALPH subchunk is only legal in the extended format, so the bare container
      # the other frames get would leave the file undecodable.
      it "wraps the frame in a VP8X header flagged for alpha" do
        data = File.binread(helper.webp_single_frame_source(alpha_webp))

        expect(data[12, 4]).to eq("VP8X".b)
        expect(data.getbyte(20)).to eq(0x10)
      end
    end

    context "with a static (non-animated) WebP" do
      it "returns the source file" do
        expect(helper.webp_single_frame_source(static_webp)).to eq(static_webp)
      end
    end

    context "with a non-WebP file" do
      it "returns the source file" do
        expect(helper.webp_single_frame_source(non_webp)).to eq(non_webp)
      end
    end

    context "with a VP8X header that does not set the animation flag" do
      let(:static_vp8x) do
        crafted_webp("WEBP".b + vp8x_chunk(0x10) + "VP8 ".b + [4].pack("V") + ("\0".b * 4))
      end

      it "returns the source file" do
        expect(helper.webp_single_frame_source(static_vp8x)).to eq(static_vp8x)
      end
    end

    context "when the animation's first frame is not a recognized bitstream" do
      let(:unreadable_animation) { crafted_webp("WEBP".b + anmf_chunk(anmf_payload("JUNK"))) }

      before { allow(Rails.logger).to receive(:error) }

      # Regression guard: this used to spin forever on the same chunk
      it "returns nil without looping" do
        result = Timeout.timeout(2) { helper.webp_single_frame_source(unreadable_animation) }
        expect(result).to be_nil
      end

      it "logs the skipped image" do
        helper.webp_single_frame_source(unreadable_animation)
        expect(Rails.logger).to have_received(:error).with(/not a readable image chunk/)
      end
    end

    context "when the animation declares frames the container does not hold" do
      before { allow(Rails.logger).to receive(:error) }

      it "returns nil for an ANMF chunk too short to carry a bitstream" do
        truncated = crafted_webp("WEBP".b + anmf_chunk("\0".b * 12))
        expect(helper.webp_single_frame_source(truncated)).to be_nil
      end

      it "returns nil for an ANMF chunk whose declared size overruns the file" do
        overrun = crafted_webp("WEBP".b + vp8x_chunk(0x1e) + "ANMF".b + [9999].pack("V") + ("\0".b * 8))
        expect(helper.webp_single_frame_source(overrun)).to be_nil
      end

      # Without a VP8X flag the overrunning ANMF id is the only sign of an animation
      it "returns nil for an overrunning ANMF chunk in a container with no VP8X header" do
        headerless_overrun = crafted_webp("WEBP".b + "ANMF".b + [9999].pack("V") + ("\0".b * 8))
        expect(helper.webp_single_frame_source(headerless_overrun)).to be_nil
      end

      it "returns nil for an alpha subchunk with no bitstream behind it" do
        dangling_alpha = crafted_webp("WEBP".b + vp8x_chunk(0x1e) + anmf_chunk(anmf_payload("ALPH")))
        expect(helper.webp_single_frame_source(dangling_alpha)).to be_nil
      end

      # VP8X is a container header, so a frame claiming to be one carries no bitstream
      it "returns nil for a frame whose payload is a VP8X chunk" do
        nested_header = crafted_webp("WEBP".b + vp8x_chunk(0x1e) + anmf_chunk(anmf_payload("VP8X")))
        expect(helper.webp_single_frame_source(nested_header)).to be_nil
      end

      it "returns nil for a VP8X animation with no ANMF chunk at all" do
        headerless = crafted_webp("WEBP".b + vp8x_chunk(0x1e))
        expect(helper.webp_single_frame_source(headerless)).to be_nil
      end
    end

    context "when an error is raised while reading the file" do
      before do
        allow(File).to receive(:binread).and_raise(StandardError, "read error")
        allow(Rails.logger).to receive(:error)
      end

      it "returns nil" do
        expect(helper.webp_single_frame_source(animated_webp)).to be_nil
      end

      it "logs the error" do
        helper.webp_single_frame_source(animated_webp)
        expect(Rails.logger).to have_received(:error).with(/read error/)
      end
    end
  end
end
