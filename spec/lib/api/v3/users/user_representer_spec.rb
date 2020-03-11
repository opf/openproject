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

describe ::API::V3::Users::UserRepresenter do
  let(:status) { Principal::STATUSES[:active] }
  let(:user) { FactoryBot.build_stubbed(:user, status: status) }
  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:representer) { described_class.new(user, current_user: current_user) }

  include API::V3::Utilities::PathHelper

  context 'generation' do
    subject(:generated) { representer.to_json }

    it do is_expected.to include_json('User'.to_json).at_path('_type') end

    context 'as regular user' do
      it 'hides as much information as possible' do
        is_expected.to have_json_path('id')
        is_expected.to have_json_path('name')

        is_expected.not_to have_json_path('login')
        is_expected.not_to have_json_path('firstName')
        is_expected.not_to have_json_path('lastName')
        is_expected.not_to have_json_path('admin')
        is_expected.not_to have_json_path('updatedAt')
        is_expected.not_to have_json_path('createdAt')
        is_expected.not_to have_json_path('status')
        is_expected.not_to have_json_path('email')
      end
    end

    context 'as the represented user' do
      let(:current_user) { user }

      it 'shows the information of the user' do
        is_expected.to have_json_path('id')
        is_expected.to have_json_path('name')
        is_expected.to have_json_path('login')
        is_expected.to have_json_path('firstName')
        is_expected.to have_json_path('lastName')
        is_expected.to have_json_path('updatedAt')
        is_expected.to have_json_path('createdAt')
        is_expected.to have_json_path('status')
        is_expected.to have_json_path('email')

        is_expected.not_to have_json_path('admin')
      end
    end

    context 'as admin' do
      let(:current_user) { FactoryBot.build_stubbed(:admin) }

      it 'shows everything' do
        is_expected.to have_json_path('id')
        is_expected.to have_json_path('login')
        is_expected.to have_json_path('firstName')
        is_expected.to have_json_path('lastName')
        is_expected.to have_json_path('name')
        is_expected.to have_json_path('status')
        is_expected.to have_json_path('email')
        is_expected.to have_json_path('admin')
      end

      it_behaves_like 'has UTC ISO 8601 date and time' do
        let(:date) { user.created_on }
        let(:json_path) { 'createdAt' }
      end

      it_behaves_like 'has UTC ISO 8601 date and time' do
        let(:date) { user.updated_on }
        let(:json_path) { 'updatedAt' }
      end
    end

    describe 'email' do
      let(:user) { FactoryBot.build_stubbed(:user, status: 1, preference: preference) }

      shared_examples_for 'shows the users E-Mail address' do
        it do
          is_expected.to be_json_eql(user.mail.to_json).at_path('email')
        end
      end

      context 'user shows his E-Mail address' do
        let(:preference) { FactoryBot.build(:user_preference, hide_mail: false) }

        it_behaves_like 'shows the users E-Mail address'
      end

      context 'user hides his E-Mail address' do
        let(:preference) { FactoryBot.build(:user_preference, hide_mail: true) }

        it 'does not render the users E-Mail address' do
          is_expected
            .not_to have_json_path('email')
        end

        context 'if an admin inquires' do
          let(:current_user) { FactoryBot.build_stubbed(:admin) }

          it_behaves_like 'shows the users E-Mail address'
        end

        context 'if the user inquires himself' do
          let(:current_user) { user }

          it_behaves_like 'shows the users E-Mail address'
        end
      end
    end

    describe 'status' do
      # as only admin or self can see the status
      let(:current_user) { user }

      it 'contains the name of the account status' do
        is_expected.to be_json_eql('active'.to_json).at_path('status')
      end
    end

    describe '_links' do
      it 'should link to self' do
        expect(subject).to have_json_path('_links/self/href')
      end

      context 'showUser' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'showUser' }
          let(:href) { "/users/#{user.id}" }
        end

        context 'with a locked user' do
          let(:status) { Principal::STATUSES[:locked] }

          it_behaves_like 'has no link' do
            let(:link) { 'showUser' }
          end
        end
      end

      context 'when regular current_user' do
        it 'should have no lock-related links' do
          expect(subject).not_to have_json_path('_links/lock/href')
          expect(subject).not_to have_json_path('_links/unlock/href')
          expect(subject).not_to have_json_path('_links/update/href')
        end
      end

      context 'when current_user is admin' do
        let(:current_user) { FactoryBot.build_stubbed(:admin) }

        it 'should link to lock and update' do
          expect(subject).to have_json_path('_links/lock/href')
          expect(subject).to have_json_path('_links/updateImmediately/href')
        end

        context 'when account is locked' do
          it 'should link to unlock' do
            user.lock
            expect(subject).to have_json_path('_links/unlock/href')
          end
        end
      end

      context 'when deletion is allowed' do
        before do
          allow(Users::DeleteService).to receive(:deletion_allowed?)
            .with(user, current_user)
            .and_return(true)
        end

        it 'should link to delete' do
          expect(subject).to have_json_path('_links/delete/href')
        end
      end

      context 'when deletion is not allowed' do
        before do
          allow(Users::DeleteService).to receive(:deletion_allowed?)
            .with(user, current_user)
            .and_return(false)
        end

        it 'should not link to delete' do
          expect(subject).not_to have_json_path('_links/delete/href')
        end
      end

      describe 'memberships' do
        before do
          allow(current_user)
            .to receive(:allowed_to?) do |action, _project, options|
            permissions.include?(action) && options[:global]
          end
        end

        let(:href) do
          filters = [{ 'principal' => {
            'operator' => '=',
            'values' => [user.id.to_s]
          } }]

          api_v3_paths.path_for(:memberships, filters: filters)
        end

        context 'if the user has the :view_members permissions' do
          let(:permissions) { [:view_members] }

          it_behaves_like 'has a titled link' do
            let(:link) { 'memberships' }
            let(:title) { I18n.t(:label_member_plural) }
          end
        end

        context 'if the user has the :manage_members permissions' do
          let(:permissions) { [:manage_members] }

          it_behaves_like 'has a titled link' do
            let(:link) { 'memberships' }
            let(:title) { I18n.t(:label_member_plural) }
          end
        end

        context 'if the user lacks permissions' do
          let(:permissions) { [] }

          it_behaves_like 'has no link' do
            let(:link) { 'memberships' }
          end
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
        let(:auth_source) { FactoryBot.build_stubbed(:auth_source) }

        before do
          user.auth_source = auth_source
        end
        let!(:former_cache_key) { representer.json_cache_key }

        it 'includes the name of the representer class' do
          expect(representer.json_cache_key)
            .to include('API', 'V3', 'Users', 'UserRepresenter')
        end

        it 'changes when the locale changes' do
          I18n.with_locale(:fr) do
            expect(representer.json_cache_key)
              .not_to eql former_cache_key
          end
        end

        it 'changes when the user is updated' do
          user.updated_on = Time.now + 20.seconds

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end

        it 'changes when the user\'s auth_source is updated' do
          user.auth_source.updated_at = Time.now + 20.seconds

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end
    end
  end
end
