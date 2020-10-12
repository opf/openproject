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

describe ::API::V3::Documents::DocumentRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  let(:document) do
    FactoryBot.build_stubbed(:document,
                             description: 'Some description') do |document|
      allow(document)
        .to receive(:project)
        .and_return(project)
    end
  end
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:representer) do
    described_class.create(document, current_user: user, embed_links: true)
  end
  let(:permissions) { all_permissions }
  let(:all_permissions) { %i(manage_documents) }

  subject { representer.to_json }

  before do
    allow(user)
      .to receive(:allowed_to?) do |permission, _|
      permissions.include?(permission)
    end
  end

  describe '_links' do
    it_behaves_like 'has a titled link' do
      let(:link) { 'self' }
      let(:href) { api_v3_paths.document document.id }
      let(:title) { document.title }
    end

    it_behaves_like 'has an untitled link' do
      let(:link) { :attachments }
      let(:href) { api_v3_paths.attachments_by_document document.id }
    end

    it_behaves_like 'has a titled link' do
      let(:link) { :project }
      let(:title) { project.name }
      let(:href) { api_v3_paths.project project.id }
    end

    it_behaves_like 'has an untitled action link' do
      let(:link) { :addAttachment }
      let(:href) { api_v3_paths.attachments_by_document document.id }
      let(:method) { :post }
      let(:permission) { :manage_documents }
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'Document' }
    end

    it_behaves_like 'property', :id do
      let(:value) { document.id }
    end

    it_behaves_like 'property', :title do
      let(:value) { document.title }
    end

    it_behaves_like 'has UTC ISO 8601 date and time' do
      let(:date) { document.created_at }
      let(:json_path) { 'createdAt' }
    end

    it_behaves_like 'has UTC ISO 8601 date and time' do
      let(:date) { document.updated_at }
      let(:json_path) { 'updatedAt' }
    end

    it_behaves_like 'API V3 formattable', 'description' do
      let(:format) { 'markdown' }
      let(:raw) { document.description }
      let(:html) { '<p>' + document.description + '</p>' }
    end
  end

  describe '_embedded' do
    it 'has project embedded' do
      expect(subject)
        .to be_json_eql(project.name.to_json)
        .at_path('_embedded/project/name')
    end
  end
end
