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

describe ::API::V3::PlaceholderUsers::PlaceholderUserRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  let(:placeholder_user) { FactoryBot.build_stubbed(:placeholder_user) }
  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:representer) { described_class.new(placeholder_user, current_user: current_user) }
  let(:memberships_path) do
    filters = [
      {
        principal: {
          operator: '=',
          values: [placeholder_user.id.to_s]
        }
      }
    ]

    api_v3_paths.path_for(:memberships, filters: filters)
  end
  let(:global_permissions) { [] }

  subject(:generated) { representer.to_json }

  before do
    allow(current_user)
      .to receive(:allowed_to_globally?) do |requested_permission|
      global_permissions.include?(requested_permission)
    end
  end

  describe '_links' do
    context 'self' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.placeholder_user placeholder_user.id }
        let(:title) { placeholder_user.name }
      end
    end

    context 'showUser' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'showUser' }
        let(:href) { "/placeholder_users/#{placeholder_user.id}" }
      end
    end

    context 'delete' do
      it_behaves_like 'has no link' do
        let(:link) { 'delete' }
      end

      context 'when user allowed to manage' do
        let(:global_permissions) { [:manage_placeholder_user] }

        it_behaves_like 'has a titled link' do
          let(:link) { 'delete' }
          let(:href) { "/api/v3/placeholder_users/#{placeholder_user.id}" }
          let(:method) { :delete }
          let(:title) { "Delete #{placeholder_user.name}" }
        end
      end
    end

    context 'updateImmediately' do
      it_behaves_like 'has no link' do
        let(:link) { 'updateImmediately' }
      end

      context 'when user allowed to manage' do
        let(:global_permissions) { [:manage_placeholder_user] }

        it_behaves_like 'has a titled link' do
          let(:link) { 'updateImmediately' }
          let(:href) { "/api/v3/placeholder_users/#{placeholder_user.id}" }
          let(:method) { :patch }
          let(:title) { "Update #{placeholder_user.name}" }
        end
      end
    end

    context 'memberships' do
      it_behaves_like 'has no link' do
        let(:link) { 'memberships' }
      end

      context 'user allowed to see members' do
        let(:global_permissions) { [:view_members] }

        it_behaves_like 'has a titled link' do
          let(:link) { 'memberships' }
          let(:href) { memberships_path }
          let(:title) { I18n.t(:label_member_plural) }
        end
      end

      context 'user allowed to manage members' do
        let(:global_permissions) { [:manage_members] }

        it_behaves_like 'has a titled link' do
          let(:link) { 'memberships' }
          let(:href) { memberships_path }
          let(:title) { I18n.t(:label_member_plural) }
        end
      end
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'PlaceholderUser' }
    end

    context 'as regular user' do
      it_behaves_like 'property', :id do
        let(:value) { placeholder_user.id }
      end

      it_behaves_like 'property', :name do
        let(:value) { placeholder_user.name }
      end

      it 'hides the updatedAt property' do
        is_expected.not_to have_json_path('updatedAt')
      end

      it 'hides the createdAt property' do
        is_expected.not_to have_json_path('createdAt')
      end
    end

    context 'as admin' do
      let(:current_user) { FactoryBot.build_stubbed(:admin) }

      it_behaves_like 'property', :id do
        let(:value) { placeholder_user.id }
      end

      it_behaves_like 'property', :name do
        let(:value) { placeholder_user.name }
      end

      it_behaves_like 'datetime property', :createdAt do
        let(:value) { placeholder_user.created_at }
      end

      it_behaves_like 'datetime property', :updatedAt do
        let(:value) { placeholder_user.updated_at }
      end
    end
  end

  describe 'caching' do
    it 'is based on the representer\'s cache_key' do
      expect(OpenProject::Cache)
        .to receive(:fetch)
              .with(representer.json_cache_key)
              .and_call_original

      representer.to_json
    end

    describe '#json_cache_key' do
      let!(:former_cache_key) { representer.json_cache_key }

      it 'includes the name of the representer class' do
        expect(representer.json_cache_key)
          .to include('API', 'V3', 'PlaceholderUsers', 'PlaceholderUserRepresenter')
      end

      it 'changes when the locale changes' do
        I18n.with_locale(:fr) do
          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end

      it 'changes when the placeholder is updated' do
        placeholder_user.updated_at = Time.now + 20.seconds

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end
    end
  end
end
