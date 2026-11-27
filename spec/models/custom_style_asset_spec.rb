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

RSpec.describe CustomStyleAsset do
  let(:style) { CustomStyle.create! }
  let(:image) { Rails.root.join("spec/support/custom_styles/logos/logo_image.png") }

  let(:replacement_image) { Rails.root.join("spec/fixtures/files/image.png") }

  shared_examples "CarrierWave branding interoperability" do
    it "reads each historical mount and serves new uploads to the old uploader" do
      CustomStyle::ASSET_FIELDS.each do |field|
        old = uploader.new(style, field)
        old.store!(Rack::Test::UploadedFile.new(image))
        style.update_column(field, old.identifier)
        asset = style.reload.public_send(field)
        expect(asset.file.open(&:read)).to eq(image.binread)
        expect(asset.file.id).to eq("custom_style/#{field}/#{style.id}/logo_image.png")

        replacement = Rack::Test::UploadedFile.new(replacement_image, "image/png", original_filename: image.basename.to_s)
        style.update!(field => replacement)
        identifier = style.reload.public_send(:"#{field}_identifier")
        old.retrieve_from_store!(identifier)
        expect(old.read).to eq(replacement_image.binread)
        expect(asset.file.id).to eq("custom_style/#{field}/#{style.id}/#{identifier}")
        expect(File.binread(style.public_send(:"#{field}_path"))).to eq(replacement_image.binread)

        style.public_send(:"remove_#{field}!")
        old.retrieve_from_store!(identifier)
        expect(old.file.exists?).to be(false)
      end
    end

    it "isolates a duplicate from the original's stored and pending files" do
      style.update!(logo: Rack::Test::UploadedFile.new(image))
      style.favicon = Rack::Test::UploadedFile.new(image)
      copy = style.dup
      copy.save!
      expect(copy.logo).to be_blank
      expect(copy.favicon).to be_blank
      copy.update!(logo: Rack::Test::UploadedFile.new(replacement_image))
      copy.remove_logo!
      copy.destroy!
      style.save!
      expect(style.reload.logo.file.open(&:read)).to eq(image.binread)
      expect(style.favicon.file.open(&:read)).to eq(image.binread)
    end

    it "renders a PDF using the stored custom font" do
      style.update!(export_font_regular: Rack::Test::UploadedFile.new(Rails.public_path.join("fonts/noto/NotoSans-Regular.ttf")))
      pdf = Exports::PDF::Common::View.new(:en).document
      expect(pdf.font.family).to eq(Exports::PDF::Common::View::CUSTOM_FONT_NAME)
      pdf.text("OpenProject")
      expect(pdf.render).to start_with("%PDF")
    end

    it "preserves the original through rollback and retries the latest assignment" do
      style.update!(logo: Rack::Test::UploadedFile.new(image))
      original = style.logo.file
      first = second = nil

      CustomStyle.transaction(requires_new: true) do
        style.update!(logo: Rack::Test::UploadedFile.new(image))
        first = style.logo.file
        style.update!(logo: Rack::Test::UploadedFile.new(image))
        second = style.logo.file
        raise ActiveRecord::Rollback
      end

      expect(original).to exist
      expect(first).not_to exist
      expect(second).not_to exist
      expect(CustomStyle.find(style.id).logo.file.id).to eq(original.id)
      style.save!
      expect(style.reload.logo.file.open(&:read)).to eq(image.binread)
      expect(original).not_to exist
      replacement = style.logo.file
      style.destroy!
      expect(replacement).not_to exist
    end
  end

  context "with filesystem storage" do
    let(:uploader) { LocalFileUploader }

    let(:root) { Dir.mktmpdir }

    before do
      with_config attachments_storage: :file, attachments_storage_path: Pathname(root)
    end

    after { FileUtils.remove_entry(root) }

    include_examples "CarrierWave branding interoperability"
  end

  context "with S3 storage", if: ENV.fetch("SHRINE_TEST_S3_ENDPOINT", nil) do
    let(:bucket) { "shrine-branding-#{SecureRandom.hex(8)}" }
    let(:credentials) do
      { provider: "AWS", region: ENV.fetch("SHRINE_TEST_S3_REGION", "us-east-1"),
        endpoint: ENV.fetch("SHRINE_TEST_S3_ENDPOINT"), path_style: true,
        aws_access_key_id: ENV.fetch("SHRINE_TEST_S3_KEY"), aws_secret_access_key: ENV.fetch("SHRINE_TEST_S3_SECRET") }
    end
    let(:uploader) do
      Class.new(FogFileUploader).tap do |klass|
        klass.fog_credentials = credentials
        klass.fog_directory = bucket
        klass.fog_public = false
      end
    end

    let(:storage_bucket) { AttachmentShrine.storage_for(:s3).bucket }

    before do
      Fog.unmock!
      with_config attachments_storage: :fog, fog: { directory: bucket, credentials: }
      storage_bucket.create
    end

    after do
      storage_bucket.objects.batch_delete!
      storage_bucket.delete
    ensure
      Fog.mock!
    end

    it "can replace and reuse a filename without a ListBucket grant" do
      store = AttachmentShrine.storage_for(:store)
      allow(AttachmentShrine).to receive(:storage_for).and_call_original
      allow(AttachmentShrine).to receive(:storage_for).with(:store).and_return(store)
      allow(store).to receive(:exists?).and_raise(Aws::S3::Errors::Forbidden.new(nil, "no ListBucket"))

      legacy = uploader.new(style, :logo)
      legacy.store!(Rack::Test::UploadedFile.new(image))
      style.update_column(:logo, legacy.identifier)
      original = style.logo.file
      replacement = Rack::Test::UploadedFile.new(replacement_image, "image/png", original_filename: image.basename.to_s)

      CustomStyle.transaction(requires_new: true) do
        style.remove_logo!
        style.reload.update!(logo: replacement)
        expect(original.open(&:read)).to eq(image.binread)
        raise ActiveRecord::Rollback
      end
      expect(style.reload.logo.file.open(&:read)).to eq(image.binread)
      CustomStyle.transaction do
        style.remove_logo!
        CustomStyle.find(style.id).update!(logo: replacement)
      end
      expect(style.reload.logo.file.open(&:read)).to eq(replacement_image.binread)
      legacy.retrieve_from_store!(style.logo_identifier)
      expect(legacy.read).to eq(replacement_image.binread)
    end

    it "streams branding bytes through Rack with X-Sendfile enabled" do
      style.update!(logo: Rack::Test::UploadedFile.new(image))
      app = Rack::Sendfile.new(Rails.application, "x-sendfile")
      path = Rails.application.routes.url_helpers.custom_style_logo_path(digest: style.digest, field: :logo,
                                                                         filename: style.logo_identifier)
      response = Rack::MockRequest.new(app).get(path)
      expect(response.status).to eq(200)
      expect(response["x-sendfile"]).to be_nil
      expect(response["last-modified"]).to be_present
      expect(response["content-disposition"]).to include(image.basename.to_s)
      expect(response.body.b).to eq(image.binread)
    end

    include_examples "CarrierWave branding interoperability"
  end
end
