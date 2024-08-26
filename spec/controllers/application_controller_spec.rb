#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe ApplicationController do
  let(:user) { create(:user, lastname: "Crazy name") }

  # Fake controller to test calling an action
  controller do
    no_authorization_required! :index

    def index
      # just do anything that doesn't require an extra template
      redirect_to root_path
    end
  end

  describe "logging requesting users", with_settings: { login_required: false } do
    let(:user_message) do
      "OpenProject User: #{user.firstname} Crazy name (#{user.login} ID: #{user.id} <#{user.mail}>)"
    end

    let(:anonymous_message) { "OpenProject User: Anonymous" }

    describe "with log_requesting_user enabled" do
      before do
        allow(Rails.logger).to receive(:info)
        allow(Setting).to receive(:log_requesting_user?).and_return(true)
      end

      it "logs the current user" do
        expect(Rails.logger).to receive(:info).once.with(user_message)

        as_logged_in_user(user) do
          get(:index)
        end
      end

      it "logs an anonymous user" do
        expect(Rails.logger).to receive(:info).once.with(anonymous_message)

        # no login, so this is done as Anonymous
        get(:index)
      end
    end

    describe "with log_requesting_user disabled" do
      before do
        allow(Setting).to receive(:log_requesting_user?).and_return(false)
      end

      it "does not log the current user" do
        expect(Rails.logger).not_to receive(:info).with(user_message)

        as_logged_in_user(user) do
          get(:index)
        end
      end
    end
  end

  describe "unverified request", with_settings: { login_required: false } do
    shared_examples "handle_unverified_request resets session" do
      before do
        ActionController::Base.allow_forgery_protection = true
      end

      after do
        ActionController::Base.allow_forgery_protection = false
      end

      it "deletes the autologin cookie" do
        cookies_double = double("cookies").as_null_object

        allow(controller)
          .to receive(:cookies)
                .and_return(cookies_double)

        expect(cookies_double)
          .to receive(:delete)
                .with(OpenProject::Configuration["autologin_cookie_name"])

        post :index
      end

      it "logs out the user" do
        @controller.send(:logged_user=, create(:user))
        allow(@controller).to receive(:render_error)

        @controller.send :handle_unverified_request

        expect(@controller.send(:current_user).anonymous?).to be_truthy
      end
    end

    context "for non-API resources" do
      before do
        allow(@controller).to receive(:api_request?).and_return(false)
      end

      it_behaves_like "handle_unverified_request resets session"

      it "gives 422" do
        expect(@controller).to receive(:render_error) do |options|
          expect(options[:status]).to be(422)
        end

        @controller.send :handle_unverified_request
      end
    end

    context "for API resources" do
      before do
        allow(@controller).to receive(:api_request?).and_return(true)
      end

      it_behaves_like "handle_unverified_request resets session"

      it "does not render an error" do
        expect(@controller).not_to receive(:render_error)

        @controller.send :handle_unverified_request
      end
    end
  end

  describe "rack timeout duplicate error suppression", with_settings: { login_required: false } do
    controller do
      include OpenProjectErrorHelper

      no_authorization_required! :index

      def index
        op_handle_error "fail"

        redirect_to root_path
      end
    end

    before do
      allow(OpenProject.logger).to receive(:error)
    end

    it "doesn't suppress errors when there is no timeout" do
      get :index

      expect(OpenProject.logger).to have_received(:error) do |msg, _|
        expect(msg).to eq "fail"
      end
    end

    context "when there is a rack timeout" do
      controller do
        include OpenProjectErrorHelper
        prepend Rack::Timeout::SuppressInternalErrorReportOnTimeout

        def index
          op_handle_error "fail"

          redirect_to root_path
        end
      end

      before do
        allow(controller.request.env).to receive(:[]).and_call_original
        allow(controller.request.env)
          .to receive(:[])
                .with(Rack::Timeout::ENV_INFO_KEY)
                .and_return(OpenStruct.new(state: :timed_out))
      end

      it "suppresses the (duplicate) error report" do
        get :index

        expect(OpenProject.logger).not_to have_received(:error)
      end
    end

    context "when used outside of a controller" do
      let(:object) do
        klass = Class.new(Object) do
          include OpenProjectErrorHelper
          prepend Rack::Timeout::SuppressInternalErrorReportOnTimeout
        end

        klass.new
      end

      it "does nothing as there is no duplicate to suppress" do
        expect { object.op_handle_error "fail" }.not_to raise_error

        expect(OpenProject.logger).to have_received(:error)
      end
    end
  end
end
