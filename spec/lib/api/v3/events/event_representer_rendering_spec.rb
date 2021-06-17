#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
#++

require 'spec_helper'

describe ::API::V3::Events::EventRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  let(:recipient) { FactoryBot.build_stubbed(:user) }
  let(:event) { FactoryBot.build_stubbed(:event, recipient: recipient, read_ian: read_ian, read_email: read_email) }
  let(:representer) { described_class.create(event, current_user: recipient) }

  let(:read_ian) { false }
  let(:read_email) { false }

  subject(:generated) { representer.to_json }

  describe 'self link' do
    it_behaves_like 'has a titled link' do
      let(:link) { 'self' }
      let(:href) { api_v3_paths.event event.id }
      let(:title) { event.subject }
    end
  end

  describe 'IAN read and unread links' do
    context 'when unread' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'readIAN' }
        let(:href) { api_v3_paths.event_read_ian event.id }
        let(:method) { :post }
      end

      it_behaves_like 'has no link' do
        let(:link) { 'unreadIAN' }
      end
    end

    context 'when read' do
      let(:read_ian) { true }

      it_behaves_like 'has an untitled link' do
        let(:link) { 'unreadIAN' }
        let(:href) { api_v3_paths.event_unread_ian event.id }
        let(:method) { :post }
      end

      it_behaves_like 'has no link' do
        let(:link) { 'readIAN' }
      end
    end
  end

  describe 'Email read and unread links' do
    context 'when unread' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'readEmail' }
        let(:href) { api_v3_paths.event_read_email event.id }
        let(:method) { :post }
      end

      it_behaves_like 'has no link' do
        let(:link) { 'unreadEmail' }
      end
    end

    context 'when read' do
      let(:read_email) { true }

      it_behaves_like 'has an untitled link' do
        let(:link) { 'unreadEmail' }
        let(:href) { api_v3_paths.event_unread_email event.id }
        let(:method) { :post }
      end

      it_behaves_like 'has no link' do
        let(:link) { 'readEmail' }
      end
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'Event' }
    end

    it_behaves_like 'property', :id do
      let(:value) { event.id }
    end

    it_behaves_like 'property', :subject do
      let(:value) { event.subject }
    end

    it_behaves_like 'property', :reason do
      let(:value) { event.reason }
    end

    it_behaves_like 'datetime property', :createdAt do
      let(:value) { event.created_at }
    end

    it_behaves_like 'datetime property', :updatedAt do
      let(:value) { event.updated_at }
    end
  end
end
