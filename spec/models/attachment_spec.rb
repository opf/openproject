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

RSpec.describe Attachment do
  let(:stubbed_author) { build_stubbed(:user) }
  let(:author) { create(:user) }
  let(:long_description) { "a" * 300 }
  let(:work_package) { create(:work_package) }
  let(:stubbed_work_package) { build_stubbed(:work_package) }
  let(:file) { create(:uploaded_jpg, name: "test.jpg") }
  let(:second_file) { create(:uploaded_jpg, name: "test2.jpg") }
  let(:container) { stubbed_work_package }

  let(:attachment) do
    build(
      :attachment,
      author:,
      container:,
      content_type: nil, # so that it is detected
      file:
    )
  end
  let(:stubbed_attachment) do
    build_stubbed(
      :attachment,
      author: stubbed_author,
      container:
    )
  end

  describe "validations" do
    it "is valid" do
      expect(stubbed_attachment)
        .to be_valid
    end

    context "with a long description" do
      before do
        stubbed_attachment.description = long_description
        stubbed_attachment.valid?
      end

      it "raises an error regarding description length" do
        expect(stubbed_attachment.errors[:description])
          .to contain_exactly(I18n.t("activerecord.errors.messages.too_long", count: 255))
      end
    end

    context "without a container" do
      let(:container) { nil }

      it "is valid" do
        expect(stubbed_attachment)
          .to be_valid
      end
    end

    context "without a container first and then setting a container" do
      let(:container) { nil }

      before do
        stubbed_attachment.container = work_package
      end

      it "is valid" do
        expect(stubbed_attachment)
          .to be_valid
      end
    end

    context "with a container first and then removing the container" do
      before do
        stubbed_attachment.container = nil
      end

      it "notes the field as unchangeable" do
        stubbed_attachment.valid?

        expect(stubbed_attachment.errors.symbols_for(:container))
          .to contain_exactly(:unchangeable)
      end
    end

    context "with a container first and then changing the container_id" do
      before do
        stubbed_attachment.container_id = stubbed_attachment.container_id + 1
      end

      it "notes the field as unchangeable" do
        stubbed_attachment.valid?

        expect(stubbed_attachment.errors.symbols_for(:container))
          .to contain_exactly(:unchangeable)
      end
    end

    context "with a container first and then changing the container_type" do
      before do
        stubbed_attachment.container_type = "WikiPage"
      end

      it "notes the field as unchangeable" do
        stubbed_attachment.valid?

        expect(stubbed_attachment.errors.symbols_for(:container))
          .to contain_exactly(:unchangeable)
      end
    end
  end

  describe "#containered?" do
    it "is false if the attachment has no container" do
      stubbed_attachment.container = nil

      expect(stubbed_attachment)
        .not_to be_containered
    end

    it "is true if the attachment has a container" do
      expect(stubbed_attachment)
        .to be_containered
    end
  end

  describe "create" do
    it("creates a jpg file called test") do
      expect(File.exist?(attachment.diskfile.path)).to be true
    end

    it('has the content type "image/jpeg"') do
      expect(attachment.content_type).to eq "image/jpeg"
    end

    it "has the correct filesize" do
      expect(attachment.filesize)
        .to eql file.size
    end

    it "creates an md5 digest" do
      expect(attachment.digest)
        .to eql Digest::MD5.file(file.path).hexdigest
    end
  end

  describe "two attachments with same file name" do
    let(:second_file) { create(:uploaded_jpg, name: file.original_filename) }

    it "does not interfere" do
      a1 = Attachment.create!(container: work_package,
                              file:,
                              author:)
      a2 = Attachment.create!(container: work_package,
                              file: second_file,
                              author:)

      expect(a1.diskfile.path)
        .not_to eql a2.diskfile.path
    end
  end

  ##
  # The tests assumes the default, file-based storage is configured and tests against that.
  # I.e. it does not test fog attachments being deleted from the cloud storage (such as S3).
  describe "#destroy" do
    before do
      attachment.save!

      expect(File.exist?(attachment.file.path)).to be true

      attachment.destroy
      attachment.run_callbacks(:commit)
      # triggering after_commit callbacks manually as they are not triggered during rspec runs
      # though in dev/production mode destroy does trigger these callbacks
    end

    it "deletes the attachment's file" do
      expect(File.exist?(attachment.file.path)).to be false
    end
  end

  it_behaves_like "creates an audit trail on destroy" do
    subject { create(:attachment) }
  end

  # We just use with_direct_uploads here to make sure the
  # FogAttachment class is defined and Fog is mocked.
  describe "#external_url", :with_direct_uploads do
    let(:author) { create(:user) }

    let(:image_path) { Rails.root.join("spec/fixtures/files/image.png") }
    let(:text_path) { Rails.root.join("spec/fixtures/files/testfile.txt") }
    let(:binary_path) { Rails.root.join("spec/fixtures/files/textfile.txt.gz") }

    let(:image_attachment) { FogAttachment.new author:, file: File.open(image_path) }
    let(:text_attachment) { FogAttachment.new author:, file: File.open(text_path) }
    let(:binary_attachment) { FogAttachment.new author:, file: File.open(binary_path) }

    shared_examples "it has a temporary download link" do
      let(:url_options) { {} }
      let(:query) { attachment.external_url(**url_options).to_s.split("?").last }

      it "has a default expiry time" do
        expect(query).to include "X-Amz-Expires="
        expect(query).not_to include "X-Amz-Expires=3600"
      end

      context "with a custom expiry time" do
        let(:url_options) { { expires_in: 1.hour } }

        it "uses that time" do
          expect(query).to include "X-Amz-Expires=3600"
        end
      end

      context "with expiry time exceeding maximum" do
        let(:url_options) { { expires_in: 1.year } }

        it "uses the allowed max" do
          expect(query).to include "X-Amz-Expires=#{OpenProject::Configuration.fog_download_url_expires_in}"
        end
      end
    end

    shared_examples "it uses content disposition inline" do
      let(:attachment) { raise "define me!" }

      describe "the external url (for remote attachments)" do
        it "contains inline content disposition without the filename" do
          expect(attachment.external_url.to_s).to include "response-content-disposition=inline&"
        end
      end

      describe "content disposition (for local attachments)" do
        it "is inline, including the filename" do
          expect(attachment.content_disposition).to eq "inline; filename=#{attachment.filename}"
        end
      end
    end

    describe "for an image file" do
      before { image_attachment.save! }

      it_behaves_like "it uses content disposition inline" do
        let(:attachment) { image_attachment }
      end

      # this is independent from the type of file uploaded so we just test this for the first one
      it_behaves_like "it has a temporary download link" do
        let(:attachment) { image_attachment }
      end
    end

    describe "for a text file" do
      before { text_attachment.save! }

      it_behaves_like "it uses content disposition inline" do
        let(:attachment) { text_attachment }
      end
    end

    describe "for a video file" do
      let(:attachment) { described_class.new }

      it "assumes it to be inlineable" do
        %w[video/webm video/mp4 video/quicktime].each do |content_type|
          attachment.content_type = content_type
          expect(attachment).to be_inlineable, "#{content_type} should be inlineable"
        end
      end
    end

    describe "for a binary file" do
      before { binary_attachment.save! }

      it "makes S3 use content_disposition 'attachment; filename=...'" do
        expect(binary_attachment.content_disposition).to eq "attachment; filename=textfile.txt.gz"
        expect(binary_attachment.external_url.to_s).to include "response-content-disposition=attachment"
      end
    end
  end

  describe "virus scan job on commit" do
    shared_let(:work_package) { create(:work_package) }
    let(:created_attachment) do
      create(:attachment,
             status: :uploaded,
             container: work_package)
    end

    context "with setting disabled", with_settings: { antivirus_scan_mode: :disabled } do
      it "does not run" do
        attachment.save
        expect(attachment.pending_virus_scan?).to be false

        expect(Attachments::VirusScanJob)
          .not_to have_been_enqueued.with(attachment)
      end
    end

    context "with setting enabled",
            with_ee: %i[virus_scanning],
            with_settings: { antivirus_scan_mode: :clamav_socket } do
      it "runs the job" do
        attachment.save
        expect(attachment.pending_virus_scan?).to be true

        expect(Attachments::VirusScanJob)
          .to have_been_enqueued.with(attachment)
      end
    end
  end

  describe "full text extraction job on commit" do
    let(:created_attachment) do
      create(:attachment,
             author:,
             container:)
    end

    shared_examples_for "runs extraction" do
      it "runs extraction" do
        extraction_with_id = nil

        allow(Attachments::ExtractFulltextJob)
          .to receive(:perform_later) do |id|
          extraction_with_id = id
        end

        attachment.save

        expect(extraction_with_id).to eql attachment.id
      end
    end

    shared_examples_for "does not run extraction" do
      it "does not run extraction" do
        created_attachment

        expect(Attachments::ExtractFulltextJob)
          .not_to receive(:perform_later)

        created_attachment.save
      end
    end

    context "for a work package" do
      let(:work_package) { create(:work_package) }
      let(:container) { work_package }

      context "on create" do
        it_behaves_like "runs extraction"
      end

      context "on update" do
        it_behaves_like "does not run extraction"
      end
    end

    context "for a wiki page" do
      let(:wiki_page) { create(:wiki_page) }
      let(:container) { wiki_page }

      context "on create" do
        it_behaves_like "does not run extraction"
      end

      context "on update" do
        it_behaves_like "does not run extraction"
      end
    end

    context "without a container" do
      let(:container) { nil }

      context "on create" do
        it_behaves_like "runs extraction"
      end

      context "on update" do
        it_behaves_like "does not run extraction"
      end
    end
  end
end
