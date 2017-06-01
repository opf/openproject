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

describe ::API::V3::Attachments::AttachmentRepresenter do
  include API::V3::Utilities::PathHelper

  let(:current_user) {
    FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
  }
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:all_permissions) { [:view_work_packages, :edit_work_packages] }
  let(:permissions) { all_permissions }

  let(:container) { FactoryGirl.create(:work_package, project: project) }

  let(:attachment) { FactoryGirl.create(:attachment, container: container) }
  let(:representer) {
    ::API::V3::Attachments::AttachmentRepresenter.new(attachment, current_user: current_user)
  }

  subject { representer.to_json }

  it { is_expected.to be_json_eql('Attachment'.to_json).at_path('_type') }
  it { is_expected.to be_json_eql(attachment.id.to_json).at_path('id') }
  it { is_expected.to be_json_eql(attachment.filename.to_json).at_path('fileName') }
  it { is_expected.to be_json_eql(attachment.filesize.to_json).at_path('fileSize') }
  it { is_expected.to be_json_eql(attachment.content_type.to_json).at_path('contentType') }

  it_behaves_like 'API V3 formattable', 'description' do
    let(:format) { 'plain' }
    let(:raw) { attachment.description }
  end

  it_behaves_like 'API V3 digest' do
    let(:path) { 'digest' }
    let(:algorithm) { 'md5' }
    let(:hash) { attachment.digest }
  end

  it_behaves_like 'has UTC ISO 8601 date and time' do
    let(:date) { attachment.created_on }
    let(:json_path) { 'createdAt' }
  end

  describe '_links' do
    it_behaves_like 'has a titled link' do
      let(:link) { 'self' }
      let(:href) { api_v3_paths.attachment(attachment.id) }
      let(:title) { attachment.filename }
    end

    it_behaves_like 'has a titled link' do
      let(:link) { 'container' }
      let(:href) { api_v3_paths.work_package(attachment.container.id) }
      let(:title) { attachment.container.subject }
    end

    it_behaves_like 'has a titled link' do
      let(:link) { 'author' }
      let(:href) { api_v3_paths.user(attachment.author.id) }
      let(:title) { attachment.author.name }
    end

    describe 'delete link' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'delete' }
        let(:href) { api_v3_paths.attachment(attachment.id) }
      end

      it 'has the DELETE method' do
        is_expected.to be_json_eql('delete'.to_json).at_path('_links/delete/method')
      end

      context 'user is not allowed to edit the container' do
        let(:permissions) { all_permissions - [:edit_work_packages] }

        it_behaves_like 'has no link' do
          let(:link) { 'delete' }
        end
      end
    end
  end
end
