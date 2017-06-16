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

describe ::API::V3::Users::UserRepresenter do
  let(:user) { FactoryGirl.build_stubbed(:user, status: 1) }
  let(:current_user) { FactoryGirl.build_stubbed(:user) }
  let(:representer) { described_class.new(user, current_user: current_user) }

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

        is_expected.not_to have_json_path('admin')
      end
    end

    context 'as admin' do
      let(:current_user) { FactoryGirl.build_stubbed(:admin) }

      it 'shows everything' do
       is_expected.to have_json_path('id')
       is_expected.to have_json_path('login')
       is_expected.to have_json_path('firstName')
       is_expected.to have_json_path('lastName')
       is_expected.to have_json_path('name')
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
      context 'user shows his E-Mail address' do
        let(:preference) { FactoryGirl.build(:user_preference, hide_mail: false) }
        let(:user) { FactoryGirl.build_stubbed(:user, status: 1, preference: preference) }

        it 'shows the users E-Mail address' do
          is_expected.to be_json_eql(user.mail.to_json).at_path('email')
        end
      end

      context 'user hides his E-Mail address' do
        let(:preference) { FactoryGirl.build(:user_preference, hide_mail: true) }
        let(:user) { FactoryGirl.build_stubbed(:user, status: 1, preference: preference) }

        it 'does not render the users E-Mail address' do
          is_expected.to be_json_eql(nil.to_json).at_path('email')
        end
      end
    end

    describe 'status' do
      it 'contains the name of the account status' do
        is_expected.to be_json_eql('active'.to_json).at_path('status')
      end
    end

    describe '_links' do
      it 'should link to self' do
        expect(subject).to have_json_path('_links/self/href')
      end

      it_behaves_like 'has an untitled link' do
        let(:link) { 'showUser' }
        let(:href) { "/users/#{user.id}" }
      end

      context 'when regular current_user' do
        it 'should have no lock-related links' do
          expect(subject).not_to have_json_path('_links/lock/href')
          expect(subject).not_to have_json_path('_links/unlock/href')
          expect(subject).not_to have_json_path('_links/update/href')
        end
      end

      context 'when current_user is admin' do
        let(:current_user) { FactoryGirl.build_stubbed(:admin) }

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
          allow(DeleteUserService).to receive(:deletion_allowed?)
            .with(user, current_user)
            .and_return(true)
        end

        it 'should link to delete' do
          expect(subject).to have_json_path('_links/delete/href')
        end
      end

      context 'when deletion is not allowed' do
        before do
          allow(DeleteUserService).to receive(:deletion_allowed?)
            .with(user, current_user)
            .and_return(false)
        end

        it 'should not link to delete' do
          expect(subject).not_to have_json_path('_links/delete/href')
        end
      end
    end

    describe 'avatar', with_settings: { gravatar_enabled?: true, protocol: 'http' } do
      before do
        user.mail = 'foo@bar.com'
      end

      it 'should have an url to gravatar if settings permit and mail is set' do
        expect(parse_json(subject, 'avatar')).to start_with('http://gravatar.com/avatar')
      end

      it 'should be blank if gravatar is disabled' do
        allow(Setting).to receive(:gravatar_enabled?).and_return(false)

        expect(parse_json(subject, 'avatar')).to be_blank
      end

      it 'should be blank if email is missing (e.g. anonymous)' do
        user.mail = nil

        expect(parse_json(subject, 'avatar')).to be_blank
      end
    end
  end
end
