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

RSpec.describe Attachments::ExtractFulltextJob, type: :job do
  subject(:extracted_attributes) do
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
    create(:attachment)
  end
  let(:plaintext_file_handler) do
    Plaintext::Resolver.file_handlers.find { |h| h.accept? attachment.content_type }.tap do |plaintext_file_handler|
      if plaintext_file_handler.nil?
        fail "Plaintext::FileHandler not found for content type #{attachment.content_type}"
      end
    end
  end

  it "is enqueued on Attachment creation" do
    attachment = create(:attachment)
    expect(described_class)
      .to have_been_enqueued
      .with(attachment.id)
  end

  it "is not enqueued on Attachment update" do
    attachment = create(:attachment)
    clear_enqueued_jobs
    attachment.touch
    expect(described_class)
      .not_to have_been_enqueued
  end

  context "with successful text extraction" do
    before do
      allow(plaintext_file_handler).to receive(:text).and_return(text)
    end

    context "when the attachment is readable" do
      before do
        allow(attachment).to receive(:readable?).and_return(true)
      end

      it "updates the attachment's DB record with fulltext, fulltext_tsv, and file_tsv" do
        perform_enqueued_jobs
        expect(extracted_attributes["fulltext"]).to eq text
        expect(extracted_attributes["fulltext_tsv"].size).to be > 0
        expect(extracted_attributes["file_tsv"].size).to be > 0
      end

      context "without text extracted" do
        let(:text) { nil }

        # include_examples 'no fulltext but file name saved as TSV'
        it "updates the attachment's DB record with file_tsv" do
          perform_enqueued_jobs
          expect(extracted_attributes["fulltext"]).to be_blank
          expect(extracted_attributes["fulltext_tsv"]).to be_blank
          expect(extracted_attributes["file_tsv"].size).to be > 0
        end
      end
    end
  end

  context "when the plaintext handler returns a frozen string (Bug #68047)" do
    let(:frozen_text) { "frozen string".freeze } # rubocop:disable Style/RedundantFreeze

    before do
      allow(plaintext_file_handler).to receive(:text).and_return(frozen_text)
    end

    it "updates the attachment's DB record with fulltext, fulltext_tsv, and file_tsv" do
      perform_enqueued_jobs
      expect(extracted_attributes["fulltext"]).to eq frozen_text
      expect(extracted_attributes["fulltext_tsv"].size).to be > 0
      expect(extracted_attributes["file_tsv"].size).to be > 0
    end
  end

  context "with the file not readable" do
    before do
      allow(Attachment)
        .to receive(:find_by).with(id: attachment.id)
        .and_return(attachment)
      allow(attachment).to receive(:readable?).and_return(false)
    end

    it "updates the attachment's DB record with file_tsv" do
      perform_enqueued_jobs
      expect(extracted_attributes["fulltext"]).to be_blank
      expect(extracted_attributes["fulltext_tsv"]).to be_blank
      expect(extracted_attributes["file_tsv"].size).to be > 0
    end
  end

  context "with exception during extraction" do
    let(:exception_message) { "boom-internal-error" }
    let(:logger) { Rails.logger }

    before do
      allow(plaintext_file_handler).to receive(:text).and_raise(exception_message)

      allow(logger).to receive(:error)

      allow(attachment).to receive(:readable?).and_return(true)
    end

    it "raises the exception to update Job's internal state" do
      expect { perform_enqueued_jobs }.to raise_error(exception_message)
    end

    it "logs the exception" do
      perform_enqueued_jobs rescue nil
      expect(logger).to have_received(:error).with(/boom-internal-error/)
    end

    it "updates the attachment's DB record with file_tsv from the filename" do
      perform_enqueued_jobs rescue nil
      expect(extracted_attributes["fulltext"]).to be_blank
      expect(extracted_attributes["fulltext_tsv"]).to be_blank
      expect(extracted_attributes["file_tsv"].size).to be > 0
    end
  end
end
