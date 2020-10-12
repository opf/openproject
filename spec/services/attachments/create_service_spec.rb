#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.

require 'spec_helper'

describe Attachments::CreateService do
  let(:user) { FactoryBot.create(:user) }
  let(:work_package) { FactoryBot.create(:work_package) }
  let(:container) { work_package }
  let(:description) { 'a fancy description' }

  subject { described_class.new(container, author: user) }

  describe '#call' do
    def call_tested_method
      subject.call uploaded_file: FileHelpers.mock_uploaded_file(name: 'foobar.txt'),
                   description: description
    end

    shared_examples 'successful creation' do
      it 'saves the attachment' do
        attachment = Attachment.first
        expect(attachment.filename).to eq 'foobar.txt'
        expect(attachment.description).to eq description
      end

      it 'adds the attachment to the WP' do
        container.reload
        expect(container.attachments).to include Attachment.first
      end

      it 'adds a journal entry on the WP' do
        expect(container.journals.count).to eq 2 # 1 for WP creation + 1 for the attachment
      end
    end

    context 'happy path' do
      before do
        call_tested_method
      end

      it_behaves_like 'successful creation'
    end

    context "invalid container" do
      before do
        # have an invalid work package
        work_package.subject = ''

        call_tested_method
      end

      it_behaves_like 'successful creation'
    end

    context "uncontainered" do
      let(:container) { nil }

      before do
        call_tested_method
      end

      it 'saves the attachment' do
        attachment = Attachment.first
        expect(attachment.filename).to eq 'foobar.txt'
        expect(attachment.description).to eq description
      end
    end

    context 'invalid attachment', with_settings: { attachment_max_size: 0 } do
      it 'raises the exception' do
        expect { call_tested_method }
          .to raise_exception ActiveRecord::RecordInvalid
      end

      it 'does not create the attachment' do
        begin
          call_tested_method
        rescue ActiveRecord::RecordInvalid
          # expected
        end

        expect(Attachment.count)
          .to eq 0
      end
    end
  end
end
