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

RSpec.describe Exports::PDF::Common::Attachments do
  let(:helper) do
    obj = Object.new
    obj.extend(described_class)
    # api_url_helpers is defined in Exports::PDF::Common::Common, not in
    # Attachments. Provide a minimal implementation so the module methods work.
    obj.define_singleton_method(:api_url_helpers) { API::V3::Utilities::PathHelper::ApiV3Path }
    obj
  end

  describe "#pdf_embeddable?" do
    %w[image/jpeg image/png image/gif image/webp].each do |type|
      it "returns true for #{type}" do
        expect(helper.pdf_embeddable?(type)).to be true
      end
    end

    %w[application/pdf text/plain image/svg+xml application/binary].each do |type|
      it "returns false for #{type}" do
        expect(helper.pdf_embeddable?(type)).to be false
      end
    end
  end

  describe "#temp_image_file" do
    after { helper.delete_all_resized_images }

    it "returns a string path ending with the given extension" do
      path = helper.temp_image_file(".png")
      expect(path).to end_with(".png")
    end

    it "registers the temp file so delete_all_resized_images can clean it up" do
      helper.temp_image_file(".png")
      expect { helper.delete_all_resized_images }.not_to raise_error
    end

    it "accumulates multiple temp files" do
      helper.temp_image_file(".png")
      helper.temp_image_file(".jpg")
      expect { helper.delete_all_resized_images }.not_to raise_error
    end
  end

  describe "#delete_all_resized_images" do
    it "does not raise when no images have been created yet" do
      expect { helper.delete_all_resized_images }.not_to raise_error
    end

    it "calls close! on each registered temp file" do
      tmp1 = instance_double(Tempfile)
      tmp2 = instance_double(Tempfile)
      allow(tmp1).to receive(:close!)
      allow(tmp2).to receive(:close!)

      helper.instance_variable_set(:@resized_images, [tmp1, tmp2])
      helper.delete_all_resized_images

      expect(tmp1).to have_received(:close!)
      expect(tmp2).to have_received(:close!)
    end

    it "resets the list to an empty array" do
      tmp = instance_double(Tempfile)
      allow(tmp).to receive(:close!)
      helper.instance_variable_set(:@resized_images, [tmp])
      helper.delete_all_resized_images
      expect(helper.instance_variable_get(:@resized_images)).to eq([])
    end
  end

  describe "#resize_image" do
    let(:png_fixture) { Rails.root.join("spec/fixtures/files/image.png").to_s }

    after { helper.delete_all_resized_images }

    it "returns a path string" do
      result = helper.resize_image(png_fixture)
      expect(result).to be_a(String)
    end

    it "writes the resized image to the returned path" do
      result = helper.resize_image(png_fixture)
      expect(File.exist?(result)).to be true
      expect(File.size(result)).to be > 0
    end

    it "writes a file with image/png MIME type" do
      result = helper.resize_image(png_fixture)
      expect(Marcel::MimeType.for(Pathname.new(result))).to eq("image/png")
    end
  end

  describe "#convert_gif_to_png" do
    # Use the PNG fixture as a stand-in; MiniMagick handles it fine.
    let(:source_fixture) { Rails.root.join("spec/fixtures/files/image.png").to_s }

    after { helper.delete_all_resized_images }

    it "returns a path ending with .png" do
      result = helper.convert_gif_to_png(source_fixture)
      expect(result).to end_with(".png")
    end

    it "writes a non-empty file to the returned path" do
      result = helper.convert_gif_to_png(source_fixture)
      expect(File.exist?(result)).to be true
      expect(File.size(result)).to be > 0
    end

    it "writes a file with image/png MIME type" do
      result = helper.convert_gif_to_png(source_fixture)
      expect(Marcel::MimeType.for(Pathname.new(result))).to eq("image/png")
    end
  end

  describe "#convert_webp_to_png" do
    let(:webp_fixture) { Rails.root.join("spec/fixtures/files/image.webp").to_s }

    after { helper.delete_all_resized_images }

    it "returns a path ending with .png" do
      result = helper.convert_webp_to_png(webp_fixture)
      expect(result).to end_with(".png")
    end

    it "writes a non-empty PNG file" do
      result = helper.convert_webp_to_png(webp_fixture)
      expect(File.exist?(result)).to be true
      expect(File.size(result)).to be > 0
    end

    it "writes a file with image/png MIME type" do
      result = helper.convert_webp_to_png(webp_fixture)
      expect(Marcel::MimeType.for(Pathname.new(result))).to eq("image/png")
    end

    it "falls back to the source file when extract_first_webp_frame returns nil" do
      allow(helper).to receive(:extract_first_webp_frame).and_return(nil)
      result = helper.convert_webp_to_png(webp_fixture)
      expect(result).to end_with(".png")
      expect(File.exist?(result)).to be true
      expect(Marcel::MimeType.for(Pathname.new(result))).to eq("image/png")
    end
  end

  describe "#attachment_image_local_file" do
    let(:attachment)    { instance_double(Attachment, id: 42) }
    let(:file_uploader) { instance_double(LocalFileUploader) }
    let(:local_file)    { instance_double(File, path: "/some/path/image.png") }

    context "when the file is accessible" do
      before do
        allow(attachment).to receive(:file).and_return(file_uploader)
        allow(file_uploader).to receive(:local_file).and_return(local_file)
      end

      it "returns the local file object" do
        expect(helper.attachment_image_local_file(attachment)).to eq(local_file)
      end
    end

    context "when accessing the file raises an error" do
      before do
        allow(attachment).to receive(:file).and_return(file_uploader)
        allow(file_uploader).to receive(:local_file).and_raise(StandardError, "disk error")
        allow(Rails.logger).to receive(:error)
      end

      it "returns nil" do
        expect(helper.attachment_image_local_file(attachment)).to be_nil
      end

      it "logs the error including the attachment id" do
        helper.attachment_image_local_file(attachment)
        expect(Rails.logger).to have_received(:error).with(/42/)
      end
    end
  end

  describe "#attachment_by_api_content_src" do
    # api_url_helpers returns the ApiV3Path class; stub root_path on the class itself.
    before do
      allow(API::V3::Utilities::PathHelper::ApiV3Path).to receive(:root_path).and_return("/")
    end

    it "returns nil for an empty src" do
      expect(helper.attachment_by_api_content_src("")).to be_nil
    end

    it "returns nil when src does not start with root_path" do
      expect(helper.attachment_by_api_content_src("https://evil.example.com/attachments/1/file.png")).to be_nil
    end

    it "returns nil when src does not contain the attachments pattern" do
      expect(helper.attachment_by_api_content_src("/api/v3/some_other_path")).to be_nil
    end

    context "when src matches a valid attachment path" do
      let(:attachment) { instance_double(Attachment, id: 7) }

      before { allow(Attachment).to receive(:find_by).with(id: 7).and_return(attachment) }

      context "when the attachment is visible" do
        before { allow(attachment).to receive(:visible?).and_return(true) }

        it "returns the attachment for the api/v3 path" do
          result = helper.attachment_by_api_content_src("/api/v3/attachments/7/content")
          expect(result).to eq(attachment)
        end

        it "returns the attachment for the drag-and-drop path format" do
          result = helper.attachment_by_api_content_src("/attachments/7/filename.ext")
          expect(result).to eq(attachment)
        end
      end

      context "when the attachment is not visible" do
        before { allow(attachment).to receive(:visible?).and_return(false) }

        it "returns nil" do
          result = helper.attachment_by_api_content_src("/api/v3/attachments/7/content")
          expect(result).to be_nil
        end
      end
    end

    context "when no attachment with that id exists" do
      before { allow(Attachment).to receive(:find_by).and_return(nil) }

      it "returns nil" do
        expect(helper.attachment_by_api_content_src("/attachments/999/file.png")).to be_nil
      end
    end

    context "when an unexpected error is raised" do
      before do
        allow(Attachment).to receive(:find_by).and_raise(StandardError, "db error")
        allow(Rails.logger).to receive(:error)
      end

      it "returns nil" do
        expect(helper.attachment_by_api_content_src("/attachments/1/file.png")).to be_nil
      end

      it "logs the error" do
        helper.attachment_by_api_content_src("/attachments/1/file.png")
        expect(Rails.logger).to have_received(:error)
      end
    end
  end

  describe "#attachment_image_filepath" do
    let(:src) { "/api/v3/attachments/1/content" }
    let(:attachment) { instance_double(Attachment, id: 1, content_type: "image/jpeg") }
    let(:local_file) { instance_double(File, path: "/tmp/image.jpg") }

    before do
      allow(helper).to receive(:attachment_by_api_content_src).with(src).and_return(attachment)
      allow(helper).to receive(:pdf_embeddable?).with("image/jpeg").and_return(true)
      allow(helper).to receive(:attachment_image_local_file).with(attachment).and_return(local_file)
      allow(helper).to receive(:resize_image).with("/tmp/image.jpg").and_return("/tmp/resized.jpg")
    end

    it "returns a resized image path for a jpeg" do
      expect(helper.attachment_image_filepath(src)).to eq("/tmp/resized.jpg")
    end

    context "when attachment is nil" do
      before { allow(helper).to receive(:attachment_by_api_content_src).with(src).and_return(nil) }

      it "returns nil" do
        expect(helper.attachment_image_filepath(src)).to be_nil
      end
    end

    context "when content_type is not embeddable" do
      before { allow(helper).to receive(:pdf_embeddable?).with("image/jpeg").and_return(false) }

      it "returns nil" do
        expect(helper.attachment_image_filepath(src)).to be_nil
      end
    end

    context "when local_file is nil" do
      before { allow(helper).to receive(:attachment_image_local_file).with(attachment).and_return(nil) }

      it "returns nil" do
        expect(helper.attachment_image_filepath(src)).to be_nil
      end
    end

    context "when the attachment is a GIF" do
      let(:attachment) { instance_double(Attachment, id: 1, content_type: "image/gif") }
      let(:local_file) { instance_double(File, path: "/tmp/image.gif") }

      before do
        allow(helper).to receive(:attachment_by_api_content_src).with(src).and_return(attachment)
        allow(helper).to receive(:pdf_embeddable?).with("image/gif").and_return(true)
        allow(helper).to receive(:attachment_image_local_file).with(attachment).and_return(local_file)
        allow(helper).to receive(:convert_gif_to_png).with("/tmp/image.gif").and_return("/tmp/converted.png")
        allow(helper).to receive(:resize_image).with("/tmp/converted.png").and_return("/tmp/resized.png")
      end

      it "converts the GIF to PNG before resizing" do
        result = helper.attachment_image_filepath(src)
        expect(helper).to have_received(:convert_gif_to_png).with("/tmp/image.gif")
        expect(result).to eq("/tmp/resized.png")
      end
    end

    context "when the attachment is a WebP" do
      let(:attachment) { instance_double(Attachment, id: 1, content_type: "image/webp") }
      let(:local_file) { instance_double(File, path: "/tmp/image.webp") }

      before do
        allow(helper).to receive(:attachment_by_api_content_src).with(src).and_return(attachment)
        allow(helper).to receive(:pdf_embeddable?).with("image/webp").and_return(true)
        allow(helper).to receive(:attachment_image_local_file).with(attachment).and_return(local_file)
        allow(helper).to receive(:convert_webp_to_png).with("/tmp/image.webp").and_return("/tmp/converted.png")
        allow(helper).to receive(:resize_image).with("/tmp/converted.png").and_return("/tmp/resized.png")
      end

      it "converts the WebP to PNG before resizing" do
        result = helper.attachment_image_filepath(src)
        expect(helper).to have_received(:convert_webp_to_png).with("/tmp/image.webp")
        expect(result).to eq("/tmp/resized.png")
      end
    end

    context "when gif conversion returns nil" do
      let(:attachment) { instance_double(Attachment, id: 1, content_type: "image/gif") }
      let(:local_file) { instance_double(File, path: "/tmp/image.gif") }

      before do
        allow(helper).to receive(:attachment_by_api_content_src).with(src).and_return(attachment)
        allow(helper).to receive(:pdf_embeddable?).with("image/gif").and_return(true)
        allow(helper).to receive(:attachment_image_local_file).with(attachment).and_return(local_file)
        allow(helper).to receive(:convert_gif_to_png).with("/tmp/image.gif").and_return(nil)
      end

      it "returns nil" do
        expect(helper.attachment_image_filepath(src)).to be_nil
      end
    end
  end

  describe "#extract_first_webp_frame" do
    let(:animated_webp) { Rails.root.join("spec/fixtures/files/animated.webp").to_s }
    let(:static_webp)   { Rails.root.join("spec/fixtures/files/image.webp").to_s }
    let(:non_webp)      { Rails.root.join("spec/fixtures/files/image.png").to_s }

    after { helper.delete_all_resized_images }

    context "with an animated WebP" do
      it "returns a non-nil path" do
        expect(helper.extract_first_webp_frame(animated_webp)).not_to be_nil
      end

      it "returns a path to an existing file" do
        result = helper.extract_first_webp_frame(animated_webp)
        expect(File.exist?(result)).to be true
      end

      it "returns a file with image/webp MIME type" do
        result = helper.extract_first_webp_frame(animated_webp)
        expect(Marcel::MimeType.for(Pathname.new(result))).to eq("image/webp")
      end

      it "returns a single-frame WebP" do
        result = helper.extract_first_webp_frame(animated_webp)
        expect(MiniMagick::Image.open(result).frames.count).to eq(1)
      end

      it "returns a file with a valid RIFF/WEBP container header" do
        result = helper.extract_first_webp_frame(animated_webp)
        data = File.binread(result)
        expect(data[0, 4]).to eq("RIFF".b)
        expect(data[8, 4]).to eq("WEBP".b)
      end
    end

    context "with a static (non-animated) WebP" do
      it "returns nil" do
        expect(helper.extract_first_webp_frame(static_webp)).to be_nil
      end
    end

    context "with a non-WebP file" do
      it "returns nil" do
        expect(helper.extract_first_webp_frame(non_webp)).to be_nil
      end
    end

    context "when an error is raised while reading the file" do
      before do
        allow(File).to receive(:binread).and_raise(StandardError, "read error")
        allow(Rails.logger).to receive(:error)
      end

      it "returns nil" do
        expect(helper.extract_first_webp_frame(animated_webp)).to be_nil
      end

      it "logs the error" do
        helper.extract_first_webp_frame(animated_webp)
        expect(Rails.logger).to have_received(:error).with(/read error/)
      end
    end
  end
end
