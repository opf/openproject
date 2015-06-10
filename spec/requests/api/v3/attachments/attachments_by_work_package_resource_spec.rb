#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Attachments by work package resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper
  include FileHelpers

  let(:current_user) {
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  }
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages] }
  let(:work_package) { FactoryGirl.create(:work_package, author: current_user, project: project) }

  subject(:response) { last_response }

  before do
    allow(User).to receive(:current).and_return current_user
    FactoryGirl.create_list(:attachment, 5, container: work_package)
  end

  describe '#get' do
    let(:get_path) { api_v3_paths.attachments_by_work_package work_package.id }

    before do
      get get_path
    end

    it 'should respond with 200' do
      expect(subject.status).to eq(200)
    end

    it_behaves_like 'API V3 collection response', 5, 5, 'Attachment'
  end

  describe '#post' do
    let(:permissions) { [:view_work_packages, :edit_work_packages] }

    let(:request_path) { api_v3_paths.attachments_by_work_package work_package.id }
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
        let(:message) { "fileName #{I18n.t('activerecord.errors.messages.blank')}." }
      end
    end

    context 'file is too large' do
      let(:file) { mock_uploaded_file(content: 'a' * 2.kilobytes) }
      let(:expanded_localization) {
        I18n.t('activerecord.errors.messages.file_too_large', count: max_file_size.kilobytes)
      }

      it_behaves_like 'constraint violation' do
        let(:message) { "File #{expanded_localization}." }
      end
    end
  end
end
