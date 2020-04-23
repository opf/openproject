#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

shared_examples 'an APIv3 attachment resource', type: :request, content_type: :json do |include_by_container = true|
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper
  include FileHelpers

  let(:current_user) { user_with_permissions }

  let(:user_with_permissions) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end

  let(:author) do
    current_user
  end

  let(:project) { FactoryBot.create(:project, public: false) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }

  let(:attachment) { FactoryBot.create(:attachment, container: container, author: author) }
  let(:container) { send attachment_type }

  let(:attachment_type) { raise "attachment type goes here, e.g. work_package" }
  let(:permissions) { all_permissions }

  let(:all_permissions) { Array([create_permission, read_permission, update_permission]).flatten.compact }

  let(:create_permission) { raise "permissions go here, e.g. add_work_packages" }
  let(:read_permission) { raise "permissions go here, e.g. view_work_packages" }
  let(:update_permission) { raise "permissions go here, e.g. edit_work_packages" }

  let(:missing_permissions_user) { user_with_permissions }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe '#get' do
    subject(:response) { last_response }
    let(:get_path) { api_v3_paths.attachment attachment.id }

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
        let(:current_user) { missing_permissions_user }
        let(:permissions) { all_permissions - Array(read_permission) }

        it_behaves_like 'not found' do
          let(:type) { 'Attachment' }
        end
      end
    end
  end

  describe '#post' do
    let(:permissions) { Array(update_permission) }

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
      let(:permissions) do
        # Some attachables use public permissions
        # which more or less allows everybody to upload attachments.
        # This messes with the tests.
        # However, it might make sense to reevaluate the necessity of this test.
        allow(Redmine::Acts::Attachable)
          .to receive(:attachables)
          .and_return(Redmine::Acts::Attachable.attachables.select do |a|
            permission = OpenProject::AccessControl.permission(a.attachable_options[:add_on_new_permission])
            !permission || !permission.public?
          end)

        []
      end

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
        if permissions.any? || read_permission.nil?
          expect(subject.status).to eq status
        else
          # In case no permissions are left, the user is not allowed to see the attachment
          # and will thus receive a 404.
          expect(subject.status).to eq 404
        end
      end

      it 'does not delete the attachment' do
        expect(Attachment.exists?(attachment.id)).to be_truthy
      end
    end

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
      let(:permissions) { all_permissions - Array(update_permission) }

      it_behaves_like 'does not delete the attachment'
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
      shared_examples 'for a local file' do
        let(:mock_file) { raise "define mock_file" }
        let(:content_disposition) { raise "define content_disposition" }

        let(:attachment) do
          att = FactoryBot.create(:attachment, container: container, file: mock_file, author: current_user)

          att.file.store!
          att.send :write_attribute, :file, mock_file.original_filename
          att.send :write_attribute, :content_type, mock_file.content_type
          att.save!
          att
        end

        it 'responds with 200 OK' do
          expect(subject.status).to eq 200
        end

        it 'has the necessary headers for content and caching' do
          expect(subject.headers['Content-Disposition'])
            .to eql content_disposition

          expect(subject.headers['Content-Type'])
            .to eql mock_file.content_type

          expect(subject.headers["Cache-Control"]).to eq "public, max-age=604799"
          expect(subject.headers["Expires"]).to be_present

          expires_time = Time.parse response.headers["Expires"]

          expect(expires_time < Time.now.utc + 604799).to be_truthy
          expect(expires_time > Time.now.utc + 604799 - 60).to be_truthy
        end

        it 'sends the file in binary' do
          expect(subject.body)
            .to match(mock_file.read)
        end
      end

      context 'for a local text file' do
        it_behaves_like 'for a local file' do
          let(:mock_file) { FileHelpers.mock_uploaded_file name: 'foobar.txt' }
          let(:content_disposition) { "inline; filename=foobar.txt" }
        end
      end

      context 'for a local binary file' do
        it_behaves_like 'for a local file' do
          let(:mock_file) { FileHelpers.mock_uploaded_file name: 'foobar.dat', content_type: "application/octet-stream" }
          let(:content_disposition) { "attachment; filename=foobar.dat" }
        end
      end

      context 'for a local json file' do
        it_behaves_like 'for a local file' do
          let(:mock_file) do
            FileHelpers.mock_uploaded_file(name: 'foobar.json',
                                           content_type: "application/json",
                                           content: '{"id": "12342"}')
          end
          let(:content_disposition) { "attachment; filename=foobar.json" }
        end
      end

      context 'for a remote file' do
        let(:external_url) { 'http://some_service.org/blubs.gif' }
        let(:mock_file) { FileHelpers.mock_uploaded_file name: 'foobar.txt' }
        let(:attachment) do
          FactoryBot.create(:attachment, container: container, file: mock_file, author: current_user).tap do
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

          expect(subject.headers["Cache-Control"]).to eq "public, max-age=604799"
          expect(subject.headers["Expires"]).to be_present

          expires_time = Time.parse response.headers["Expires"]

          expect(expires_time < Time.now.utc + 604799).to be_truthy
          expect(expires_time > Time.now.utc + 604799 - 60).to be_truthy
        end
      end
    end
  end

  context 'by container', if: include_by_container do
    subject(:response) { last_response }

    describe '#get' do
      let(:get_path) { api_v3_paths.send "attachments_by_#{attachment_type}", container.id }

      before do
        FactoryBot.create_list(:attachment, 2, container: container)
        get get_path
      end

      it 'should respond with 200' do
        expect(subject.status).to eq(200)
      end

      it_behaves_like 'API V3 collection response', 2, 2, 'Attachment'
    end

    describe '#post' do
      let(:request_path) { api_v3_paths.send "attachments_by_#{attachment_type}", container.id }
      let(:request_parts) { { metadata: metadata, file: file } }
      let(:metadata) { { fileName: 'cat.png' }.to_json }
      let(:file) { mock_uploaded_file(name: 'original-filename.txt') }
      let(:max_file_size) { 1 } # given in kiB

      before do
        allow(Setting).to receive(:attachment_max_size).and_return max_file_size.to_s
        post request_path, request_parts
      end

      it 'should respond with HTTP Created' do
        expect(subject.status).to eq(201)
      end

      it 'should return the new attachment' do
        expect(subject.body).to be_json_eql('Attachment'.to_json).at_path('_type')
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

      context 'only allowed to add, but not to edit' do
        let(:permissions) { all_permissions - Array(update_permission) }

        it_behaves_like 'unauthorized access'
      end

      context 'only allowed to view' do
        let(:permissions) { Array(read_permission) }

        it_behaves_like 'unauthorized access'
      end
    end
  end
end
