#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

# Concern is included into AccountController and depends on methods available there
describe AccountController do

  context 'GET #omniauth_login' do
    before do
      Setting.stub(:self_registration?).and_return(true)
      Setting.stub(:self_registration).and_return('3')
    end

    describe 'register' do
      context 'with on-the-fly registration' do
        let(:omniauth_hash) do
          OmniAuth::AuthHash.new(
            provider: 'google',
            uid: '123545',
            info: { name: 'foo',
                    email: 'foo@bar.com',
                    first_name: 'foo',
                    last_name: 'bar'
            }
          )
        end

        before do
          request.env['omniauth.auth'] = omniauth_hash
          request.env['omniauth.origin'] = 'https://example.net/some_back_url'
          get :omniauth_login
        end

        it 'registers the user on-the-fly' do
          user = User.find_by_login('foo@bar.com')
          expect(user).to be_an_instance_of(User)
          expect(user.auth_source_id).to be_nil
          expect(user.current_password).to be_nil
          expect(user.identity_url).to eql('google:123545')
        end

        it 'redirects to the first login page with a back_url' do
          expect(response).to redirect_to(
            my_first_login_path(:back_url => 'https://example.net/some_back_url'))
        end
      end

      context 'with redirect to register form' do
        let(:omniauth_hash) do
          OmniAuth::AuthHash.new(
            provider: 'google',
            uid: '123545',
            info: { name: 'foo', email: 'foo@bar.com' }
            # first_name and last_name not set
          )
        end

        it 'renders user form' do
          request.env['omniauth.auth'] = omniauth_hash
          get :omniauth_login
          expect(response).to render_template :register
        end

        it 'registers user via post' do
          auth_source_registration = omniauth_hash.merge(
            omniauth: true,
            timestamp: Time.new)
          session[:auth_source_registration] = auth_source_registration
          post :register, :user => { :firstname => 'Foo',
                                     :lastname => 'Smith',
                                     :mail => 'foo@bar.com' }
          expect(response).to redirect_to my_first_login_path

          user = User.find_by_login('foo@bar.com')
          expect(user).to be_an_instance_of(User)
          expect(user.auth_source_id).to be_nil
          expect(user.current_password).to be_nil
          expect(user.identity_url).to eql('google:123545')
        end
      end
    end

    describe 'login' do
      let(:omniauth_hash) do
        OmniAuth::AuthHash.new(
          provider: 'google',
          uid: '123545',
          info: { name: 'foo',
                  email: 'foo@bar.com'
          }
        )
      end
      it 'should sign in the user after successful external authentication' do
        request.env['omniauth.auth'] = omniauth_hash
        FactoryGirl.create(:user, force_password_change: false, identity_url: 'google:123545')
        get :omniauth_login
        expect(response).to redirect_to controller: 'my', action: 'page'
      end
    end

    describe 'Error occurs during authentication' do
      it 'should redirect to login page' do
        get :omniauth_failure
        expect(response).to redirect_to signin_path
      end

      it 'should log a warn message' do
        expect(Rails.logger).to receive(:warn).with('invalid_credentials')
        get :omniauth_failure, message: 'invalid_credentials'
      end
    end
  end

  describe '#identity_url_from_omniauth' do
    let(:omniauth_hash) { { provider: 'developer', uid: 'veryuniqueid' } }

    it 'should return the correct identity_url' do
      result = AccountController.new.send(:identity_url_from_omniauth, omniauth_hash)
      expect(result).to eql('developer:veryuniqueid')
    end
  end

end
