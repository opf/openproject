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
require "net/http"

RSpec.describe "Shrine S3 attachment lifecycle", if: ENV.fetch("SHRINE_TEST_S3_ENDPOINT", nil) do
  include_context "with real database commits" if ENV.fetch("SHRINE_TEST_S3_ENDPOINT", nil)

  let(:endpoint) { ENV.fetch("SHRINE_TEST_S3_ENDPOINT") }
  let(:region) { ENV.fetch("SHRINE_TEST_S3_REGION", "us-east-1") }
  let(:bucket) { "shrine-spike-#{SecureRandom.hex(8)}" }
  let(:credentials) do
    { provider: "AWS", endpoint:, path_style: true, region:,
      aws_access_key_id: ENV.fetch("SHRINE_TEST_S3_KEY"), aws_secret_access_key: ENV.fetch("SHRINE_TEST_S3_SECRET") }
  end
  let(:storage) { AttachmentShrine.storage_for(:s3) }
  let(:user) { create(:admin) }
  let(:bytes) { "signed browser upload\n" }

  before do |example|
    with_config attachments_storage: :fog, direct_uploads: true, fog: { directory: bucket, credentials: }
    storage.bucket.create
    example.metadata[:created_bucket] = storage.bucket
    allow(User).to receive(:current).and_return(user)
  end

  after do |example|
    created = example.metadata.delete(:created_bucket)
    if created
      created.objects.batch_delete!
      created.delete
    end
  end

  def upload(link, content)
    uri = URI(link.fetch("href"))
    Tempfile.create("browser-file", binmode: true) do |file|
      file.write(content)
      file.rewind
      request = Net::HTTP::Post.new(uri)
      request.set_form(link.fetch("form_fields").to_a + [["file", file, { filename: "example.txt" }]], "multipart/form-data")
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
    end
  end

  def read_via_api(link)
    get link.fetch("href")
    expect(last_response).to have_http_status(:found)
    response = Net::HTTP.get_response(URI(last_response.headers.fetch("Location")))
    expect(response.code).to eq("200"), response.body
    response.body
  end

  def prepare_upload
    metadata = { fileName: "example.txt", fileSize: bytes.bytesize, contentType: "text/plain" }
    post "/api/v3/attachments/prepare", { metadata: metadata.to_json }, multipart: true
    expect(last_response.status).to eq(201), last_response.body
    JSON.parse(last_response.body)
  end

  it "reads prepared bytes, rolls back completion, retries and deletes the stage after commit" do
    response = prepare_upload
    links = response.fetch("_links")
    id = response.fetch("id")
    posted = upload(links.fetch("addAttachment"), bytes)
    expect(posted.code).to eq("201"), posted.body
    expect(read_via_api(links.fetch("downloadLocation"))).to eq(bytes)
    get links.fetch("completeUpload").fetch("href")
    expect(last_response).to have_http_status(:ok)
    expect(Attachments::FinishDirectUploadJob).to have_been_enqueued.with(id)

    stage = links.fetch("addAttachment").fetch("form_fields").fetch("key")
    final = "uploads/attachment/file/#{id}/example.txt"
    Attachment.transaction do
      Attachments::FinishDirectUploadJob.perform_now(id)
      expect(Attachment.find(id)).to be_status_uploaded
      expect(storage.exists?(final)).to be(true)
      expect(storage.exists?(stage)).to be(true)
      raise ActiveRecord::Rollback
    end
    expect(Attachment.find(id)).to be_status_prepared
    expect(storage.exists?(final)).to be(false)
    expect(read_via_api(links.fetch("downloadLocation"))).to eq(bytes)

    Attachments::FinishDirectUploadJob.perform_now(id)
    expect(storage.exists?(stage)).to be(false)
    expect(Attachment.find(id).digest).to eq(Digest::MD5.hexdigest(bytes))
    expect(read_via_api(links.fetch("downloadLocation"))).to eq(bytes)
  end

  def verify_metadata_rollback(row)
    downloaded = row.diskfile
    expect(downloaded.read).to eq(bytes)
    Attachment.transaction do
      row.update!(description: "temporary description")
      raise ActiveRecord::Rollback
    end
    expect(row.reload.description).to be_blank
    expect(row.file_data).to be_nil
    expect(row.file.read).to eq(bytes)
  ensure
    downloaded&.close!
  end

  it "preserves a CarrierWave-written S3 attachment across metadata and same-name replacement rollbacks" do
    row = Attachment.create!(author: user, content_type: "text/plain", filesize: bytes.bytesize, digest: Digest::MD5.hexdigest(bytes))
    row.update_column(:file, "legacy.txt")
    Fog.unmock!
    Dir.mktmpdir do |dir|
      source = File.join(dir, "legacy.txt")
      File.binwrite(source, bytes)
      uploader = FogFileUploader.new(row, :file)
      uploader.fog_credentials = credentials
      uploader.fog_directory = bucket
      File.open(source, "rb") { |file| uploader.store!(file) }
      expect(row.reload.file_data).to be_nil
      verify_metadata_rollback(row)

      File.binwrite(source, "replacement")
      Attachment.transaction do
        File.open(source, "rb") { |file| row.file = file }
        row.save!
        expect(row.reload.file.read).to eq("replacement")
        raise ActiveRecord::Rollback
      end
      expect(row.reload.file_data).to be_nil
      expect(row.file.read).to eq(bytes)
      expect(storage.object("uploads/attachment/file/#{row.id}/legacy.txt").get.body.read).to eq(bytes)
    end
  ensure
    Fog.mock!
  end
end
