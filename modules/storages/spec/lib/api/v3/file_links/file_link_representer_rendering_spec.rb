#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe ::API::V3::FileLinks::FileLinkRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  let(:storage) { build_stubbed(:storage) }
  let(:container) { build_stubbed(:work_package) }
  let(:creator) { build_stubbed(:user, firstname: 'Rey', lastname: 'Palpatine') }
  let(:file_link) { build_stubbed(:file_link, storage: storage, container: container, creator: creator) }
  let(:user) { build_stubbed(:user) }
  let(:representer) { described_class.new(file_link, current_user: user) }

  subject(:generated) { representer.to_json }

  describe '_links' do
    describe 'self' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { "/api/v3/file_links/#{file_link.id}" }
        let(:title) { file_link.name }
      end
    end

    describe 'storage' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'storage' }
        let(:href) { "/api/v3/storages/#{storage.id}" }
        let(:title) { storage.name }
      end
    end

    describe 'container' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'container' }
        let(:href) { "/api/v3/work_packages/#{container.id}" }
        let(:title) { container.name }
      end
    end

    describe 'creator' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'creator' }
        let(:href) { "/api/v3/users/#{creator.id}" }
        let(:title) { creator.name }
      end
    end

    describe 'delete' do
      let(:permission) { :manage_file_links }

      it_behaves_like 'has an untitled action link' do
        let(:link) { 'delete' }
        let(:href) { "/api/v3/file_links/#{file_link.id}" }
        let(:method) { :delete }
      end
    end

    describe 'originOpen' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'originOpen' }
        let(:href) { "#{storage.host}/f/#{file_link.origin_id}" }
      end
    end

    describe 'staticOriginOpen' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'staticOriginOpen' }
        let(:href) { "/api/v3/file_links/#{file_link.id}/open" }
      end
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'FileLink' }
    end

    it_behaves_like 'property', :id do
      let(:value) { file_link.id }
    end

    it_behaves_like 'datetime property', :createdAt do
      let(:value) { file_link.created_at }
    end

    it_behaves_like 'datetime property', :updatedAt do
      let(:value) { file_link.updated_at }
    end

    describe 'originData' do
      it_behaves_like 'property', 'originData/id' do
        let(:value) { file_link.origin_id }
      end

      it_behaves_like 'property', 'originData/name' do
        let(:value) { file_link.origin_name }
      end

      it_behaves_like 'property', 'originData/mimeType' do
        let(:value) { file_link.origin_mime_type }
      end

      it_behaves_like 'datetime property', 'originData/createdAt' do
        let(:value) { file_link.origin_created_at }
      end

      it_behaves_like 'datetime property', 'originData/lastModifiedAt' do
        let(:value) { file_link.origin_updated_at }
      end

      it_behaves_like 'property', 'originData/createdByName' do
        let(:value) { file_link.origin_created_by_name }
      end

      it_behaves_like 'property', 'originData/lastModifiedByName' do
        let(:value) { file_link.origin_last_modified_by_name }
      end
    end
  end
end
