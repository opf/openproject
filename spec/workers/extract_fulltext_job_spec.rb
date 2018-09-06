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
  # These jobs only get created when TSVector is supported by the DB.
  if OpenProject::Database.allows_tsv?
    let(:text) { 'lorem ipsum' }
    let(:attachment) { FactoryBot.create(:attachment) }

    context "with successful text extraction" do
      before do
        allow_any_instance_of(Plaintext::Resolver).to receive(:text).and_return(text)
      end

      context 'attachment is readable' do
        before do
          allow(attachment).to receive(:readable?).and_return(true)
          attachment.reload
        end

        it 'updates the attachment\'s DB record with fulltext, fulltext_tsv, and file_tsv' do
          expect(attachment.fulltext).to eq text
          expect(attachment.fulltext_tsv.size).to be > 0
          expect(attachment.file_tsv.size).to be > 0
        end

        # shared_examples 'no fulltext but file name saved as TSV' do
        # end

        context 'No content was extracted' do
          let(:text) { nil }

          # include_examples 'no fulltext but file name saved as TSV'
          it 'updates the attachment\'s DB record with file_tsv' do
            expect(attachment.fulltext).to be_blank
            expect(attachment.fulltext_tsv).to be_blank
            expect(attachment.file_tsv.size).to be > 0
          end
        end
      end
    end

    shared_examples 'only file name indexed' do
      it 'updates the attachment\'s DB record with file_tsv' do
        expect(attachment.fulltext).to be_blank
        expect(attachment.fulltext_tsv).to be_blank
        expect(attachment.file_tsv.size).to be > 0
      end
    end

    context 'file not readable' do
      before do
        allow(attachment).to receive(:readable?).and_return(false)
        attachment.reload
      end

      include_examples 'only file name indexed'
    end

    context 'with exception in extraction' do
      let(:exception_message) { 'boom-internal-error' }
      let(:logger) { Rails.logger }

      before do
        allow_any_instance_of(Plaintext::Resolver).to receive(:text).and_raise(exception_message)

        # This line is actually part of the test. `expect` call needs to go so far up here, as we want to verify that a message gets logged.
        expect(logger).to receive(:error).with(/boom-internal-error/)

        allow(attachment).to receive(:readable?).and_return(true)
        attachment.reload
      end

      include_examples 'only file name indexed'
    end
  end
end
