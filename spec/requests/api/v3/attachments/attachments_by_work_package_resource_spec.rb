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
  include OpenProject::Files

  let(:current_user) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
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
    let(:file) { mock_uploaded_file }

    before do
      post request_path, request_parts
    end

    it 'should respond with HTTP Created' do
      expect(subject.status).to eq(201)
    end

    it 'should return the new attachment' do
      expect(subject.body).to be_json_eql('Attachment'.to_json).at_path('_type')
    end
  end
end
