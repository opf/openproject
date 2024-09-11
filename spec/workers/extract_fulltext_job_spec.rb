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

RSpec.describe Attachments::ExtractFulltextJob, type: :job do
  subject(:extracted_attributes) do
    perform_enqueued_jobs

    attachment.reload

    Attachment.connection.select_one <<~SQL.squish
      SELECT
        fulltext,
        fulltext_tsv,
        file_tsv
      FROM
        attachments
      WHERE
        id = #{attachment.id}
    SQL
  end

  let(:text) { "lorem ipsum" }
  let(:attachment) do
    create(:attachment).tap do |attachment|
      expect(Attachments::ExtractFulltextJob)
        .to have_been_enqueued
        .with(attachment.id)

      allow(Attachment)
        .to receive(:find_by)
              .with(id: attachment.id)
              .and_return(attachment)
    end
  end

  context "with successful text extraction" do
    before do
      allow_any_instance_of(Plaintext::Resolver).to receive(:text).and_return(text)
    end

    context "attachment is readable" do
      before do
        allow(attachment).to receive(:readable?).and_return(true)
      end

      it "updates the attachment's DB record with fulltext, fulltext_tsv, and file_tsv" do
        expect(extracted_attributes["fulltext"]).to eq text
        expect(extracted_attributes["fulltext_tsv"].size).to be > 0
        expect(extracted_attributes["file_tsv"].size).to be > 0
      end

      context "without text extracted" do
        let(:text) { nil }

        # include_examples 'no fulltext but file name saved as TSV'
        it "updates the attachment's DB record with file_tsv" do
          expect(extracted_attributes["fulltext"]).to be_blank
          expect(extracted_attributes["fulltext_tsv"]).to be_blank
          expect(extracted_attributes["file_tsv"].size).to be > 0
        end
      end
    end
  end

  shared_examples "only file name indexed" do
    it "updates the attachment's DB record with file_tsv" do
      expect(extracted_attributes["fulltext"]).to be_blank
      expect(extracted_attributes["fulltext_tsv"]).to be_blank
      expect(extracted_attributes["file_tsv"].size).to be > 0
    end
  end

  context "with the file not readable" do
    before do
      allow(attachment).to receive(:readable?).and_return(false)
    end

    include_examples "only file name indexed"
  end

  context "with exception in extraction" do
    let(:exception_message) { "boom-internal-error" }
    let(:logger) { Rails.logger }

    before do
      allow_any_instance_of(Plaintext::Resolver).to receive(:text).and_raise(exception_message)

      allow(logger).to receive(:error)

      allow(attachment).to receive(:readable?).and_return(true)
    end

    it "logs the error" do
      extracted_attributes
      expect(logger).to have_received(:error).with(/boom-internal-error/)
    end

    include_examples "only file name indexed"
  end
end
