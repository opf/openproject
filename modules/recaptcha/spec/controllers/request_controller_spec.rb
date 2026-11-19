# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Recaptcha::RequestController do
  let(:user) { create(:user) }

  include_context "with settings" do
    let(:settings) do
      {
        plugin_openproject_recaptcha: {
          "recaptcha_type" => "v2",
          "website_key" => "A",
          "secret_key" => "B"
        }
      }
    end
  end

  before do
    login_as user

    session[:authenticated_user_id] = user.id
    session[:stage_secrets] = { recaptcha: "asdf" }
  end

  describe "request" do
    it "renders the template" do
      get :perform
      expect(response).to be_successful
      expect(response).to render_template "recaptcha/request/perform"
    end

    it "skips if user is verified" do
      allow(Recaptcha::Entry)
        .to receive(:exists?).with(user_id: user.id)
        .and_return true

      get :perform
      expect(response).to redirect_to stage_success_path(stage: :recaptcha, secret: "asdf")
    end

    context "if the user is an admin" do
      let(:user) { create(:admin) }

      it "skips the verification" do
        allow(controller).to receive(:perform)

        get :perform
        expect(response).to redirect_to stage_success_path(stage: :recaptcha, secret: "asdf")
        expect(controller).not_to have_received(:perform)
      end
    end
  end

  describe "verify" do
    it "succeeds assuming verification works" do
      allow(controller).to receive(:valid_recaptcha?).and_return true
      allow(controller).to receive(:save_recaptcha_verification_success!)
      post :verify
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to stage_success_path(stage: :recaptcha, secret: "asdf")
      expect(controller).to have_received(:save_recaptcha_verification_success!)
    end

    it "fails assuming verification fails" do
      allow(controller).to receive(:valid_recaptcha?).and_return false
      post :verify
      expect(flash[:error]).to be_present
      expect(response).to redirect_to stage_failure_path(stage: :recaptcha)
    end
  end
end
