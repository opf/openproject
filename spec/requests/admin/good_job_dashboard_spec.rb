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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "GoodJob administration", :skip_2fa_stage, :skip_csrf, type: :rails_request do
  let(:admin) { create(:admin) }
  let(:legacy_settings_path) { "/admin/settings/plugin/openproject_good_job_dashboard" }

  def sign_in(user)
    post Rails.application.routes.url_helpers.signin_path,
         params: { username: user.login, password: "adminADMIN!" }
    expect(session[:user_id]).to eq(user.id)
  end

  it "requires login for the administration page and engine" do
    [admin_good_job_dashboard_path, "/admin/good_job/jobs"].each do |path|
      get path
      expect(response).to redirect_to(/login/)
      expect(response.headers["WWW-Authenticate"]).to be_nil
    end
  end

  it "does not accept a mocked current user without a session" do
    login_as admin
    get "/admin/good_job/jobs"
    expect(response).to redirect_to(/login/)
  end

  it "returns unauthorized for anonymous JSON requests" do
    get "/admin/good_job/jobs", headers: { "Accept" => "application/json" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects non-administrators, including mutation requests" do
    sign_in create(:user)
    get admin_good_job_dashboard_path
    expect(response).to have_http_status(:forbidden)
    get "/admin/good_job/jobs"
    expect(response).to have_http_status(:forbidden)
    put "/admin/good_job/jobs/missing/retry"
    expect(response).to have_http_status(:forbidden)
  end

  it "embeds GoodJob and loads its pages and resources without Enterprise visibility" do
    allow(OpenProject::Configuration).to receive(:ee_manager_visible?).and_return(false)
    sign_in admin
    get admin_good_job_dashboard_path
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("iframe[src='/admin/good_job'][title='GoodJob dashboard']")).to be_present
    expect(response.parsed_body.at_css("input[name='settings[username]']")).to be_nil
    expect(response.parsed_body.at_css("input[name='settings[password]']")).to be_nil

    %w[jobs batches cron_entries processes performance].each do |path|
      get "/admin/good_job/#{path}"
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Security-Policy"]).to include("frame-ancestors 'self'")
    end

    stylesheet = response.parsed_body.at_css("link[rel='stylesheet']")["href"]
    get stylesheet
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to eq("no-store")
    get Rails.application.routes.url_helpers.signout_path
    get stylesheet
    expect(response).to have_http_status(:unauthorized)
  end

  it "redirects old settings and refuses updates" do
    sign_in admin
    get legacy_settings_path
    expect(response).to redirect_to(admin_good_job_dashboard_path)
    post legacy_settings_path, params: { settings: { username: "unused", password: "unused" } }
    expect(response).to have_http_status(:gone)
  end

  it "checks administrator privileges again on each request" do
    sign_in admin
    get "/admin/good_job/jobs"
    expect(response).to have_http_status(:ok)
    admin.update!(admin: false)
    get "/admin/good_job/jobs"
    expect(response).to have_http_status(:forbidden)
  end

  it "rejects a locked administrator" do
    sign_in admin
    admin.update!(status: User.statuses[:locked])
    get "/admin/good_job/jobs"
    expect(response).to redirect_to(/login/)
  end

  it "expires idle sessions", with_settings: { session_ttl_enabled: true, session_ttl: 5 } do
    sign_in admin
    travel 6.minutes do
      get "/admin/good_job/jobs"
      expect(response).to redirect_to(/login/)
      expect(session[:user_id]).to be_nil
    end
  end

  it "rejects access after logout" do
    sign_in admin
    get signout_path
    get "/admin/good_job/jobs"
    expect(response).to redirect_to(/login/)
  end

  it "retains CSRF protection for administrator mutations" do
    sign_in admin
    ActionController::Base.allow_forgery_protection = true
    expect do
      put "/admin/good_job/jobs/missing/retry"
    end.to raise_error(ActionController::InvalidAuthenticityToken)
  end

  it "retries a discarded job with a valid administrator session and CSRF token" do
    stub_const("DashboardRetryJob", Class.new(ApplicationJob))
    DashboardRetryJob.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
    DashboardRetryJob.disable_test_adapter
    active_job = DashboardRetryJob.new
    job = GoodJob::Job.create!(
      active_job_id: active_job.job_id,
      job_class: "DashboardRetryJob",
      serialized_params: active_job.serialize,
      queue_name: "default",
      error: "StandardError: test failure",
      scheduled_at: Time.current,
      finished_at: Time.current
    )

    sign_in admin
    ActionController::Base.allow_forgery_protection = true
    get "/admin/good_job/jobs/#{job.id}"
    expect(response).to have_http_status(:ok)
    token = response.parsed_body.at_css("meta[name='csrf-token']")["content"]

    put "/admin/good_job/jobs/#{job.id}/retry", params: { authenticity_token: token }
    expect(response).to have_http_status(:see_other)
    expect(job.reload.finished_at).to be_nil
  end
end
