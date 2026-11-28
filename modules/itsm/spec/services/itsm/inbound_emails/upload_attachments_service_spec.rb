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
require_module_spec_helper

RSpec.describe ITSM::InboundEmails::UploadAttachmentsService do
  subject(:uploads) { described_class.new(user:).call(email: ITSM::InboundEmail.new(raw), work_package:).result }

  let(:project) { create(:project) }
  let(:permissions) { %i[view_work_packages add_work_packages] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:work_package) { nil }
  let(:files) { { "report.txt" => "The report." } }
  let(:raw) do
    Mail.new(from: "jane@customer.example", body: "See attached.")
      .tap { |mail| files.each { |filename, content| mail.add_file(filename:, content:) } }
      .to_s
  end

  it "saves the files as attachments of the user, not added to anything yet" do
    expect(uploads.attachments.sole).to have_attributes(filename: "report.txt", author: user, container: nil)
    expect(File.read(uploads.attachments.sole.diskfile)).to eq("The report.")
  end

  it "has nothing to note" do
    expect(uploads.with_note("The text")).to eq("The text")
  end

  context "with a file larger than allowed", with_settings: { attachment_max_size: 1 } do
    let(:files) { { "report.txt" => "The report.", "video.mp4" => "x" * 2.kilobytes } }

    it "skips it and notes why" do
      expect(uploads.attachments.map(&:filename)).to eq(["report.txt"])
      expect(uploads.with_note("The text")).to eq("The text\n\nNot attached: `video.mp4` (larger than 1 kB)")
    end
  end

  context "with a file type that is not allowed", with_settings: { attachment_whitelist: %w[text/plain] } do
    let(:files) { { "report.txt" => "The report.", "logo.png" => "\x89PNG\r\n\x1A\n".b } }

    it "skips it and notes why" do
      expect(uploads.attachments.map(&:filename)).to eq(["report.txt"])
      expect(uploads.with_note("The text")).to eq("The text\n\nNot attached: `logo.png` (file type not allowed)")
    end
  end

  context "with a file that cannot be saved for another reason" do
    let(:create_service) { instance_double(Attachments::CreateService) }
    let(:errors) { ActiveModel::Errors.new(Attachment.new).tap { it.add(:filename, :invalid) } }

    before do
      allow(Attachments::CreateService).to receive(:new).with(user:).and_return(create_service)
      allow(create_service).to receive(:call).and_return(ServiceResult.failure(errors:))
    end

    it "skips it and notes that it could not be saved" do
      expect(uploads.attachments).to be_empty
      expect(uploads.with_note("")).to eq("Not attached: `report.txt` (could not be saved)")
    end
  end

  context "when reading a file raises" do
    let(:files) { { "report.txt" => "The report.", "photo.jpg" => "A photo." } }

    before do
      allow(ITSM::InboundEmail::Attachment).to receive(:new).and_wrap_original do |original, part|
        original.call(part).tap do |file|
          allow(file).to receive(:content).and_raise(Mail::UnknownEncodingType) if file.filename == "photo.jpg"
        end
      end
    end

    it "deletes the files saved before and raises" do
      expect { uploads }.to raise_error(Mail::UnknownEncodingType)
      expect(Attachment.count).to eq(0)
    end
  end

  context "when the user may add attachments to the work package" do
    let(:work_package) { create(:work_package, project:) }
    let(:permissions) { %i[view_work_packages add_work_package_attachments] }

    it "saves the files, not added to the work package yet" do
      expect(uploads.attachments.sole).to have_attributes(filename: "report.txt", container: nil)
    end
  end

  context "when the user may not add attachments to the work package" do
    let(:work_package) { create(:work_package, project:) }
    let(:permissions) { %i[view_work_packages add_work_package_comments] }

    it "saves nothing and notes why" do
      expect(uploads.attachments).to be_empty
      expect(Attachment.count).to eq(0)
      expect(uploads.with_note(""))
        .to eq("Not attached: `report.txt` (attachments not allowed on this work package)")
    end
  end

  describe "#remove_unclaimed" do
    let(:files) { { "report.txt" => "The report.", "photo.jpg" => "A photo." } }
    let(:claimed) { uploads.attachments.first }

    before { claimed.update!(container: create(:work_package, project:)) }

    it "deletes the attachments that were not added to anything" do
      uploads.remove_unclaimed

      expect(Attachment.all).to contain_exactly(claimed)
    end

    context "when deleting fails" do
      before { allow(OpenProject.logger).to receive(:error) }

      it "logs the error instead of raising it" do
        uploads
        allow(Attachment).to receive(:where).and_raise(Errno::EACCES)

        expect { uploads.remove_unclaimed }.not_to raise_error
        expect(OpenProject.logger).to have_received(:error).with(/Email attachments not removed/, exception: an_instance_of(Errno::EACCES))
      end
    end
  end
end
