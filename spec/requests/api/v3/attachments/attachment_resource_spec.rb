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

describe 'API v3 Attachment resource', type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) {
    FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
  }
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages] }
  let(:work_package) { FactoryGirl.create(:work_package, author: current_user, project: project) }
  let(:attachment) { FactoryGirl.create(:attachment, container: work_package) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe '#get' do
    subject(:response) { last_response }
    let(:get_path) { api_v3_paths.attachment attachment.id }

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
        let(:permissions) { [] }

        it_behaves_like 'unauthorized access'
      end
    end
  end

  describe '#delete' do
    let(:path) { api_v3_paths.attachment attachment.id }

    before do
      delete path
    end

    subject(:response) { last_response }

    context 'with required permissions' do
      let(:permissions) { [:view_work_packages, :edit_work_packages] }

      it 'responds with 202' do
        expect(subject.status).to eq 202
      end

      it 'deletes the attachment' do
        expect(Attachment.exists?(attachment.id)).not_to be_truthy
      end

      context 'for a non-existent attachment' do
        let(:path) { api_v3_paths.attachment 1337 }

        it_behaves_like 'not found' do
          let(:id) { 1337 }
          let(:type) { 'Attachment' }
        end
      end
    end

    context 'without required permissions' do
      let(:permissions) { [:view_work_packages] }

      it 'responds with 403' do
        expect(subject.status).to eq 403
      end

      it 'does not delete the attachment' do
        expect(Attachment.exists?(attachment.id)).to be_truthy
      end
    end
  end
end
