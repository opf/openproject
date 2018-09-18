#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Attachment resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper
  include FileHelpers

  let(:current_user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:author) do
    current_user
  end
  let(:project) { FactoryBot.create(:project, is_public: false) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) do
    %i[view_work_packages view_wiki_pages delete_wiki_pages_attachments
       edit_work_packages edit_wiki_pages edit_messages]
  end
  let(:work_package) { FactoryBot.create(:work_package, author: current_user, project: project) }
  let(:attachment) { FactoryBot.create(:attachment, container: container, author: author) }
  let(:wiki) { FactoryBot.create(:wiki, project: project) }
  let(:wiki_page) { FactoryBot.create(:wiki_page, wiki: wiki) }
  let(:board) { FactoryBot.create(:board, project: project) }
  let(:board_message) { FactoryBot.create(:message, board: board) }
  let(:container) { work_package }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe '#get' do
    subject(:response) { last_response }
    let(:get_path) { api_v3_paths.attachment attachment.id }

    %i[wiki_page work_package board_message].each do |attachment_type|
      context "with a #{attachment_type} attachment" do
        let(:container) { send(attachment_type) }

        context 'logged in user' do
          before do
            get get_path
          end

          it 'should respond with 200' do
            expect(subject.status).to eq(200)
          end

          it 'should respond with correct attachment' do
            expect(subject.body).to be_json_eql(attachment.filename.to_json).at_path('fileName')
          end

          context 'requesting nonexistent attachment' do
            let(:get_path) { api_v3_paths.attachment 9999 }

            it_behaves_like 'not found' do
              let(:id) { 9999 }
              let(:type) { 'Attachment' }
            end
          end

          context 'requesting attachments without sufficient permissions' do
            if attachment_type == :board_message
              let(:current_user) { FactoryBot.create(:user) }
            else
              let(:permissions) { [] }
            end

            it_behaves_like 'not found' do
              let(:type) { 'Attachment' }
            end
          end
        end
      end
    end
  end

  describe '#post' do
    let(:permissions) { %i[edit_wiki_pages] }

    let(:request_path) { api_v3_paths.attachments }
    let(:request_parts) { { metadata: metadata, file: file } }
    let(:metadata) { { fileName: 'cat.png' }.to_json }
    let(:file) { mock_uploaded_file(name: 'original-filename.txt') }
    let(:max_file_size) { 1 } # given in kiB

    before do
      allow(Setting).to receive(:attachment_max_size).and_return max_file_size.to_s
      post request_path, request_parts
    end

    subject(:response) { last_response }

    it 'should respond with HTTP Created' do
      expect(subject.status).to eq(201)
    end

    it 'should return the new attachment without container' do
      expect(subject.body).to be_json_eql('Attachment'.to_json).at_path('_type')
      expect(subject.body).to be_json_eql(nil.to_json).at_path('_links/container/href')
    end

    it 'ignores the original file name' do
      expect(subject.body).to be_json_eql('cat.png'.to_json).at_path('fileName')
    end

    context 'metadata section is missing' do
      let(:request_parts) { { file: file } }

      it_behaves_like 'invalid request body', I18n.t('api_v3.errors.multipart_body_error')
    end

    context 'file section is missing' do
      # rack-test won't send a multipart request without a file being present
      # however as long as we depend on correctly named sections this test should do just fine
      let(:request_parts) { { metadata: metadata, wrongFileSection: file } }

      it_behaves_like 'invalid request body', I18n.t('api_v3.errors.multipart_body_error')
    end

    context 'metadata section is no valid JSON' do
      let(:metadata) { '"fileName": "cat.png"' }

      it_behaves_like 'parse error'
    end

    context 'metadata is missing the fileName' do
      let(:metadata) { Hash.new.to_json }

      it_behaves_like 'constraint violation' do
        let(:message) { "fileName #{I18n.t('activerecord.errors.messages.blank')}" }
      end
    end

    context 'file is too large' do
      let(:file) { mock_uploaded_file(content: 'a' * 2.kilobytes) }
      let(:expanded_localization) do
        I18n.t('activerecord.errors.messages.file_too_large', count: max_file_size.kilobytes)
      end

      it_behaves_like 'constraint violation' do
        let(:message) { "File #{expanded_localization}" }
      end
    end

    context 'missing permissions' do
      let(:permissions) { [] }

      it_behaves_like 'unauthorized access'
    end
  end

  describe '#delete' do
    let(:path) { api_v3_paths.attachment attachment.id }

    before do
      delete path
    end

    subject(:response) { last_response }

    shared_examples_for 'deletes the attachment' do
      it 'responds with HTTP No Content' do
        expect(subject.status).to eq 204
      end

      it 'removes the attachment from the DB' do
        expect(Attachment.exists?(attachment.id)).to be_falsey
      end
    end

    shared_examples_for 'does not delete the attachment' do |status = 403|
      it "responds with #{status}" do
        expect(subject.status).to eq status
      end

      it 'does not delete the attachment' do
        expect(Attachment.exists?(attachment.id)).to be_truthy
      end
    end

    %i[wiki_page work_package board_message].each do |attachment_type|
      context "with a #{attachment_type} attachment" do
        let(:container) { send(attachment_type) }

        context 'with required permissions' do
          it_behaves_like 'deletes the attachment'

          context 'for a non-existent attachment' do
            let(:path) { api_v3_paths.attachment 1337 }

            it_behaves_like 'not found' do
              let(:id) { 1337 }
              let(:type) { 'Attachment' }
            end
          end
        end

        context 'without required permissions' do
          let(:permissions) { %i[view_work_packages view_wiki_pages] }

          it_behaves_like 'does not delete the attachment'
        end
      end
    end

    context "with an uncontainered attachment" do
      let(:container) { nil }

      context 'with the user being the author' do
        it_behaves_like 'deletes the attachment'
      end

      context 'with the user not being the author' do
        let(:author) { FactoryBot.create(:user) }

        it_behaves_like 'does not delete the attachment', 404
      end
    end
  end

  describe '#content' do
    let(:path) { api_v3_paths.attachment_content attachment.id }

    before do
      get path
    end

    subject(:response) { last_response }

    context 'with required permissions' do
      context 'for a local file' do
        let(:mock_file) { FileHelpers.mock_uploaded_file name: 'foobar.txt' }
        let(:attachment) do
          att = FactoryBot.create(:attachment, container: container, file: mock_file)

          att.file.store!
          att.send :write_attribute, :file, mock_file.original_filename
          att.send :write_attribute, :content_type, mock_file.content_type
          att.save!
          att
        end

        it 'responds with 200 OK' do
          expect(subject.status).to eq 200
        end

        it 'has the necessary headers' do
          expect(subject.headers['Content-Disposition'])
            .to eql "attachment; filename=#{mock_file.original_filename}"

          expect(subject.headers['Content-Type'])
            .to eql mock_file.content_type
        end

        it 'sends the file in binary' do
          expect(subject.body)
            .to match(mock_file.read)
        end
      end

      context 'for a remote file' do
        let(:external_url) { 'http://some_service.org/blubs.gif' }
        let(:mock_file) { FileHelpers.mock_uploaded_file name: 'foobar.txt' }
        let(:attachment) do
          FactoryBot.create(:attachment, container: container, file: mock_file) do |a|
            # need to mock here to avoid dependency on external service
            allow_any_instance_of(Attachment)
              .to receive(:external_url)
              .and_return(external_url)
          end
        end

        it 'responds with 302 Redirect' do
          expect(subject.status).to eq 302
          expect(subject.headers['Location'])
            .to eql external_url
        end
      end
    end
  end
end
