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

RSpec.describe "Restarting authentication stages", :skip_2fa_stage, :skip_csrf, type: :rails_request do
  let(:password) { "adminADMIN!" }
  let(:first_user) { create(:user, password:, password_confirmation: password, force_password_change: false) }
  let(:second_user) { create(:user, password:, password_confirmation: password, force_password_change: false) }

  before do
    OpenProject::Authentication::Stage.register :extra_step, "/login/extra_step"
  end

  after do
    OpenProject::Authentication::Stage.deregister :extra_step
  end

  it "rejects a stage success link captured before a different password login" do
    post "/login", params: { username: first_user.login, password:, back_url: "/projects" }

    expect(response).to redirect_to("/login/extra_step")

    stage = session[:authentication_stages].first
    secret = session[:stage_secrets][stage]
    kept_path = stage_success_path(stage:, secret:)

    post "/login", params: { username: second_user.login, password: }

    expect(response).to redirect_to("/login/extra_step")
    expect(session[:authenticated_user_id]).to eq(second_user.id)

    get kept_path

    expect(session[:user_id]).to be_nil
    expect(response).to redirect_to(signin_path)
  end
end
