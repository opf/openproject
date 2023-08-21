#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe Authentication::OmniauthService do
  let(:strategy) { double('Omniauth Strategy', name: 'saml') }
  let(:auth_hash) do
    OmniAuth::AuthHash.new(
      provider: 'google',
      uid: '123545',
      info: { name: 'foo',
              email: 'foo@bar.com',
              first_name: 'foo',
              last_name: 'bar' }
    )
  end
  let(:controller) { double('Controller', session: session_stub) }
  let(:session_stub) { [] }

  let(:instance) { described_class.new(strategy:, auth_hash:, controller:) }
  let(:user_attributes) { instance.send :build_omniauth_hash_to_user_attributes }

  describe '#contract' do
    before do
      allow(instance.contract)
        .to(receive(:validate))
        .and_return(valid)
    end

    context 'if valid' do
      let(:valid) { true }

      it 'calls the registration service' do
        expect(Users::RegisterUserService)
          .to(receive(:new))
          .with(kind_of(User))
          .and_call_original

        instance.call
      end
    end

    context 'if invalid' do
      let(:valid) { false }

      it 'does not call the registration service' do
        expect(Users::RegisterUserService)
          .not_to(receive(:new))

        expect(instance.contract)
          .to(receive(:errors))
          .and_return(['foo'])

        call = instance.call
        expect(call).to be_failure
        expect(call.errors).to eq ['foo']
      end
    end
  end

  describe 'activation of users' do
    let(:call) { instance.call }

    context 'with an active found user' do
      let!(:user) { create(:user, login: 'foo@bar.com', identity_url: 'google:123545') }

      it 'does not call register user service and logs in the user' do
        allow(Users::RegisterUserService).to receive(:new)

        expect(OpenProject::OmniAuth::Authorization)
          .to(receive(:after_login!))
          .with(user, auth_hash, instance)

        expect(call).to be_success
        expect(call.result).to eq user
        expect(call.result.firstname).to eq 'foo'
        expect(call.result.lastname).to eq 'bar'
        expect(call.result.mail).to eq 'foo@bar.com'

        expect(Users::RegisterUserService).not_to have_received(:new)
      end
    end

    context 'without remapping allowed',
            with_settings: { oauth_allow_remapping_of_existing_users?: false } do
      let!(:user) { create(:user, login: 'foo@bar.com') }

      it 'does not look for the user by login' do
        allow(Users::RegisterUserService).to receive(:new).and_call_original

        expect(call).not_to be_success
        expect(call.result.firstname).to eq 'foo'
        expect(call.result.lastname).to eq 'bar'
        expect(call.result.mail).to eq 'foo@bar.com'
        expect(call.result).not_to eq user
        expect(call.result).to be_new_record
        expect(call.result.errors[:login]).to eq ['has already been taken.']

        expect(Users::RegisterUserService).to have_received(:new)
      end
    end

    context 'with an active user remapped',
            with_settings: { oauth_allow_remapping_of_existing_users?: true } do
      let!(:user) { create(:user, identity_url: 'foo', login: 'foo@bar.com') }

      it 'does not call register user service and logs in the user' do
        allow(Users::RegisterUserService).to receive(:new)

        expect(OpenProject::OmniAuth::Authorization)
          .to(receive(:after_login!))
          .with(user, auth_hash, instance)

        expect(call).to be_success
        expect(call.result).to eq user
        expect(call.result.firstname).to eq 'foo'
        expect(call.result.lastname).to eq 'bar'
        expect(call.result.mail).to eq 'foo@bar.com'

        user.reload
        expect(user.firstname).to eq 'foo'
        expect(user.lastname).to eq 'bar'
        expect(user.identity_url).to eq 'google:123545'

        expect(Users::RegisterUserService).not_to have_received(:new)
      end
    end

    describe 'assuming registration/activation worked' do
      let(:register_call) { ServiceResult.new(success: register_success, message: register_message) }
      let(:register_success) { true }
      let(:register_message) { 'It worked!' }

      before do
        expect(Users::RegisterUserService).to receive_message_chain(:new, :call).and_return(register_call)
      end

      describe 'with a new user' do
        it 'calls the register service' do
          expect(call).to be_success

          # The user might get activated in the register service
          expect(instance.user).not_to be_active
          expect(instance.user).to be_new_record

          # Expect notifications to be present (Regression #38066)
          expect(instance.user.notification_settings).not_to be_empty
        end
      end
    end

    describe 'assuming registration/activation failed' do
      let(:register_success) { false }
      let(:register_message) { 'Oh noes :(' }
    end
  end

  describe '#identity_url_from_omniauth' do
    let(:auth_hash) { { provider: 'developer', uid: 'veryuniqueid', info: {} } }

    subject { instance.send(:identity_url_from_omniauth) }

    it 'returns the correct identity_url' do
      expect(subject).to eql('developer:veryuniqueid')
    end

    context 'with uid mapped from info' do
      let(:auth_hash) { { provider: 'developer', uid: 'veryuniqueid', info: { uid: 'internal' } } }

      it 'returns the correct identity_url' do
        expect(subject).to eql('developer:internal')
      end
    end
  end
end
