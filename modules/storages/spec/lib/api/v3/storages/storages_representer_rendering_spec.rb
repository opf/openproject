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

describe ::API::V3::Storages::StorageRepresenter, 'rendering' do
  let(:storage) { build_stubbed(:storage) }
  let(:user) { build_stubbed(:user) }
  let(:representer) { described_class.new(storage, current_user: user) }
  let(:connection_manager) { instance_double(::OAuthClients::ConnectionManager) }

  subject(:generated) { representer.to_json }

  before do
    allow(::OAuthClients::ConnectionManager)
      .to receive(:new).and_return(connection_manager)
    allow(connection_manager)
      .to receive(:authorization_state).and_return(:connected)
    allow(connection_manager)
      .to receive(:get_authorization_uri).and_return('https://example.com/authorize')
  end

  describe '_links' do
    describe 'self' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { "/api/v3/storages/#{storage.id}" }
        let(:title) { storage.name }
      end
    end

    describe 'origin' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'origin' }
        let(:href) { storage.host }
      end
    end

    describe 'connectionState' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'authorizationState' }
        let(:href) { 'urn:openproject-org:api:v3:storages:authorization:Connected' }
        let(:title) { 'Connected' }
      end
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'Storage' }
    end

    it_behaves_like 'property', :id do
      let(:value) { storage.id }
    end

    it_behaves_like 'datetime property', :createdAt do
      let(:value) { storage.created_at }
    end

    it_behaves_like 'datetime property', :updatedAt do
      let(:value) { storage.updated_at }
    end
  end
end
