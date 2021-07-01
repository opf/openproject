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

describe ::API::V3::Notifications::NotificationRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  shared_let(:project) { FactoryBot.create :project }
  shared_let(:resource) { FactoryBot.create :work_package, project: project }

  let(:recipient) { FactoryBot.build_stubbed(:user) }
  let(:journal) { nil }
  let(:actor) { nil }
  let(:notification) do
    FactoryBot.build_stubbed :notification,
                             recipient: recipient,
                             project: project,
                             resource: resource,
                             journal: journal,
                             actor: actor,
                             read_ian: read_ian
  end
  let(:representer) do
    described_class.create notification,
                           current_user: recipient,
                           embed_links: embed_links
  end

  let(:embed_links) { false }
  let(:read_ian) { false }

  subject(:generated) { representer.to_json }

  describe 'self link' do
    it_behaves_like 'has a titled link' do
      let(:link) { 'self' }
      let(:href) { api_v3_paths.notification notification.id }
      let(:title) { notification.subject }
    end
  end

  describe 'IAN read and unread links' do
    context 'when unread' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'readIAN' }
        let(:href) { api_v3_paths.notification_read_ian notification.id }
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
        let(:href) { api_v3_paths.notification_unread_ian notification.id }
        let(:method) { :post }
      end

      it_behaves_like 'has no link' do
        let(:link) { 'readIAN' }
      end
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'Notification' }
    end

    it_behaves_like 'property', :id do
      let(:value) { notification.id }
    end

    it_behaves_like 'property', :subject do
      let(:value) { notification.subject }
    end

    it_behaves_like 'property', :reason do
      let(:value) { notification.reason_ian }
    end

    it_behaves_like 'datetime property', :createdAt do
      let(:value) { notification.created_at }
    end

    it_behaves_like 'datetime property', :updatedAt do
      let(:value) { notification.updated_at }
    end
  end

  describe 'project' do
    it_behaves_like 'has a titled link' do
      let(:link) { 'project' }
      let(:href) { api_v3_paths.project project.id }
      let(:title) { project.name }
    end

    context 'when embedding is true' do
      let(:embed_links) { true }

      it 'embeds the context' do
        expect(generated)
          .to be_json_eql('Project'.to_json)
                .at_path("_embedded/project/_type")

        expect(generated)
          .to be_json_eql(project.name.to_json)
                .at_path("_embedded/project/name")
      end
    end
  end

  describe 'resource polymorphic resource' do
    it_behaves_like 'has a titled link' do
      let(:link) { 'resource' }
      let(:title) { resource.subject }
      let(:href) { api_v3_paths.work_package resource.id }
    end

    context 'when embedding is true' do
      let(:embed_links) { true }

      it 'embeds the resource' do
        expect(generated)
          .to be_json_eql('WorkPackage'.to_json)
                .at_path("_embedded/resource/_type")
      end
    end
  end

  describe 'actor' do
    context 'when not set' do
      it_behaves_like 'has no link' do
        let(:link) { 'actor' }
      end
    end

    context 'when set' do
      let(:actor) { FactoryBot.create :user }

      it_behaves_like 'has a titled link' do
        let(:link) { 'actor' }
        let(:href) { api_v3_paths.user actor.id }
        let(:title) { actor.name }
      end
    end
  end

  describe 'journal' do
    context 'when not set' do
      it_behaves_like 'has no link' do
        let(:link) { 'activity' }
      end
    end

    context 'when set' do
      let(:journal) { resource.journals.last }

      it_behaves_like 'has an untitled link' do
        let(:link) { 'activity' }
        let(:href) { api_v3_paths.activity journal.id }
      end

      context 'when embedding is true' do
        let(:embed_links) { true }

        it 'embeds the resource' do
          expect(generated)
            .to be_json_eql('Activity'.to_json)
                  .at_path("_embedded/activity/_type")
        end
      end
    end
  end
end
