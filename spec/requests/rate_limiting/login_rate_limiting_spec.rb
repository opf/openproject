# frozen_string_literal: true

require "spec_helper"

# Use a small burst_limit (3) so tests stay fast, and a large burst_period so
# the time-bucketed cache key never rolls over mid-test on a slow CI machine.
RSpec.describe "Rate limiting login",
               :with_rack_attack,
               with_config: { rate_limiting: { login: { burst_limit: 3, burst_period: 3600 } } },
               type: :rails_request do
  before do
    allow_any_instance_of(ActionController::Base) # rubocop:disable RSpec/AnyInstance
      .to(receive(:protect_against_forgery?))
      .and_return(false)
  end

  it "blocks after burst_limit attempts for the same username" do
    freeze_time do
      3.times do
        post signin_path, params: { username: "victim", password: "wrong" }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      post signin_path, params: { username: "victim", password: "wrong" }
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include "Too many login attempts"
    end
  end

  it "does not affect a different username" do
    freeze_time do
      3.times { post signin_path, params: { username: "victim", password: "wrong" } }

      post signin_path, params: { username: "other_user", password: "wrong" }
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end

  it "is case-insensitive on the username" do
    freeze_time do
      2.times { post signin_path, params: { username: "Victim", password: "wrong" } }
      post signin_path, params: { username: "VICTIM", password: "wrong" }

      post signin_path, params: { username: "victim", password: "wrong" }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  it "does not throttle when no username is submitted" do
    4.times { post signin_path, params: {} }
    expect(response).not_to have_http_status(:too_many_requests)
  end

  context "when disabled", with_config: { rate_limiting: { login: false } } do
    before { OpenProject::RateLimiting.set_defaults! }

    it "does not block repeated login attempts" do
      4.times do
        post signin_path, params: { username: "victim", password: "wrong" }
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end
end
