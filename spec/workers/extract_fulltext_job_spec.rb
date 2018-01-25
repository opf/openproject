#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ExtractFulltextJob, type: :job do
  let(:text) { 'lorem ipsum' }
  let(:attachment) { FactoryGirl.create(:attachment) }

  before do
    allow_any_instance_of(TextExtractor::Resolver).to receive(:text).and_return(text)
  end

  # This context can only be tested if we actually have Postgres with TSV support in our test environment.
  if OpenProject::Database.allows_tsv?
    context 'Postgres TSVECTOR available' do
      before do
        allow(attachment).to receive(:readable?).and_return(is_readable)
      end

      context 'attachment is readable' do
        let(:is_readable) { true }

        before do
          described_class.new(attachment.id).perform
          attachment.reload
        end

        it 'updates the attachment\'s DB record with fulltext, fulltext_tsv, and file_tsv' do
          expect(attachment.fulltext).to eq text
          expect(attachment.fulltext_tsv.size).to be > 0
          expect(attachment.file_tsv.size).to be > 0
        end

        context 'No content was extracted' do
          let(:text) { nil }

          it 'updates the attachment\'s DB record with file_tsv' do
            expect(attachment.fulltext).to be_blank
            expect(attachment.fulltext_tsv).to be_blank
            expect(attachment.file_tsv.size).to be > 0
          end
        end
      end

      context 'file not readable' do
        let(:is_readable) { false }

        before do
          allow_any_instance_of(Attachment).to receive(:readable?).and_return(false)
          allow(OpenProject::Database).to receive(:allows_tsv?).and_return(true)
          described_class.new(attachment.id).perform
          attachment.reload
        end

        it 'updates the attachment\'s DB record with file_tsv' do
          expect(attachment.readable?).to be_falsey
          expect(attachment.fulltext).to be_blank
          expect(attachment.fulltext_tsv).to be_blank
          expect(attachment.file_tsv.size).to be > 0
        end
      end
    end
  end

  context 'No Postgres TSVECTOR available' do
    before do
      allow(OpenProject::Database).to receive(:allows_tsv?).and_return(false)
      described_class.new(attachment.id).perform
      attachment.reload
    end

    it 'updates the attachment\'s DB record with fulltext only' do
      expect(attachment.fulltext).to eq(text)
      expect(attachment.fulltext_tsv).to be_nil
      expect(attachment.file_tsv).to be_nil
    end
  end
end
