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

describe ApplicationController, type: :controller do
  let(:user) { FactoryBot.create(:user, lastname: "Crazy! Name with \r\n Newline") }

  # Fake controller to test calling an action
  controller do
    def index
      # just do anything that doesn't require an extra template
      redirect_to root_path
    end
  end

  describe 'logging requesting users' do
    let(:user_message) do
      "OpenProject User: #{user.firstname} Crazy! Name with \#\# " +
        "Newline (#{user.login} ID: #{user.id} <#{user.mail}>)"
    end

    let(:anonymous_message) { 'OpenProject User: Anonymous' }

    describe 'with log_requesting_user enabled' do
      before do
        allow(Rails.logger).to receive(:info)
        allow(Setting).to receive(:log_requesting_user?).and_return(true)
      end

      it 'should log the current user' do
        expect(Rails.logger).to receive(:info).once.with(user_message)

        as_logged_in_user(user) do
          get(:index)
        end
      end

      it 'should log an anonymous user' do
        expect(Rails.logger).to receive(:info).once.with(anonymous_message)

        # no login, so this is done as Anonymous
        get(:index)
      end
    end

    describe 'with log_requesting_user disabled' do
      before do
        allow(Setting).to receive(:log_requesting_user?).and_return(false)
      end

      it 'should not log the current user' do
        expect(Rails.logger).not_to receive(:info).with(user_message)

        as_logged_in_user(user) do
          get(:index)
        end
      end
    end
  end

  describe 'unverified request' do
    shared_examples 'handle_unverified_request resets session' do
      before do
        ActionController::Base.allow_forgery_protection = true
      end

      after do
        ActionController::Base.allow_forgery_protection = false
      end

      it 'deletes the autologin cookie' do
        cookies_double = double('cookies').as_null_object

        allow(controller)
          .to receive(:cookies)
          .and_return(cookies_double)

        expect(cookies_double)
          .to receive(:delete)
          .with(OpenProject::Configuration['autologin_cookie_name'])

        post :index
      end

      it 'logs out the user' do
        @controller.send(:logged_user=, FactoryBot.create(:user))
        allow(@controller).to receive(:render_error)

        @controller.send :handle_unverified_request

        expect(@controller.send(:current_user).anonymous?).to be_truthy
      end
    end

    context 'for non-API resources' do
      before do
        allow(@controller).to receive(:api_request?).and_return(false)
      end

      it_behaves_like 'handle_unverified_request resets session'

      it 'should give 422' do
        expect(@controller).to receive(:render_error) do |options|
          expect(options[:status]).to eql(422)
        end

        @controller.send :handle_unverified_request
      end
    end

    context 'for API resources' do
      before do
        allow(@controller).to receive(:api_request?).and_return(true)
      end

      it_behaves_like 'handle_unverified_request resets session'

      it 'should not render an error' do
        expect(@controller).not_to receive(:render_error)

        @controller.send :handle_unverified_request
      end
    end
  end
end
