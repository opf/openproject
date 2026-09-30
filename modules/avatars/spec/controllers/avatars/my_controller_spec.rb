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

require_relative "../../spec_helper"
require_relative "../../shared_examples"

RSpec.describe Avatars::MyAvatarController do
  include_context "there are users with and without avatars"
  let(:user) { user_without_avatar }
  let(:enabled) { true }

  before do
    login_as user
    allow(OpenProject::Avatars::AvatarManager).to receive(:avatars_enabled?).and_return enabled
  end

  describe "#update" do
    context "when not logged in" do
      let(:user) { User.anonymous }

      it "renders 403" do
        post :update
        expect(response).to redirect_to signin_path(back_url: edit_my_avatar_url)
      end
    end

    context "when not enabled" do
      let(:enabled) { false }

      it "renders 404" do
        post :update
        expect(response).to have_http_status :not_found
      end
    end

    it "returns invalid method for post request" do
      post :update
      expect(response).not_to be_successful
      expect(response).to have_http_status :method_not_allowed
    end

    it "calls the service for put" do
      expect_any_instance_of(Avatars::UpdateService)
        .to receive(:replace)
        .and_return(ServiceResult.success)

      put :update
      expect(response).to be_successful
      expect(response).to have_http_status :ok
    end

    it "calls the service for put" do
      expect_any_instance_of(Avatars::UpdateService)
        .to receive(:replace)
        .and_return(ServiceResult.failure)

      put :update
      expect(response).not_to be_successful
      expect(response).to have_http_status :bad_request
    end
  end

  describe "#delete" do
    it "returns invalid method for post request" do
      post :destroy
      expect(response).not_to be_successful
      expect(response).to have_http_status :method_not_allowed
    end

    it "calls the service for delete" do
      expect_any_instance_of(Avatars::UpdateService)
        .to receive(:destroy)
        .and_return(ServiceResult.success(result: "message"))

      delete :destroy
      expect(flash[:notice]).to include "message"
      expect(flash[:error]).not_to be_present
      expect(response.body).to include 'action="reload"'
    end

    it "calls the service for delete" do
      result = ServiceResult.failure
      result.errors.add :base, "error"

      expect_any_instance_of(Avatars::UpdateService)
        .to receive(:destroy)
        .and_return(result)

      delete :destroy
      expect(flash[:notice]).not_to be_present
      expect(flash[:error]).to include "error"
      expect(response.body).to include 'action="reload"'
    end
  end
end
