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

RSpec.describe "Rate limiting registration",
               :with_rack_attack,
               type: :rails_request do
  before do
    allow_any_instance_of(ActionController::Base) # rubocop:disable RSpec/AnyInstance
      .to(receive(:protect_against_forgery?))
      .and_return(false)
  end

  def register!(ip_address: "192.0.2.1")
    post account_register_path,
         params: {
           user: {
             login: "spam#{SecureRandom.hex(4)}",
             mail: "#{SecureRandom.hex(4)}@example.com",
             firstname: "Spam",
             lastname: "User",
             password: "adminADMIN!",
             password_confirmation: "adminADMIN!"
           }
         },
         headers: { "REMOTE_ADDR" => ip_address, "Content-Type": "multipart/form-data" }
  end

  context "when enabled per IP",
          with_settings: { registration_rate_limit: 3 } do
    before { OpenProject::RateLimiting.set_defaults! }

    it "blocks the fourth attempt from the same IP" do
      3.times do
        register!
        expect(response).not_to have_http_status(:too_many_requests)
      end

      register!
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include "Too many registration attempts"
    end

    it "does not block a different IP" do
      3.times { register!(ip_address: "192.0.2.1") }

      register!(ip_address: "198.51.100.1")
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end

  context "when enabled per instance",
          with_settings: { registration_rate_limit: 3, registration_rate_limit_per_ip: false } do
    before { OpenProject::RateLimiting.set_defaults! }

    it "blocks the fourth attempt on the instance regardless of IP" do
      3.times do
        register!
        expect(response).not_to have_http_status(:too_many_requests)
      end

      register!(ip_address: "198.51.100.1")
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include "Too many registration attempts"
    end

    it "does not share the limit across host names" do
      3.times { register! }

      allow(Setting).to receive(:host_name).and_return("other.example.com")

      register!
      expect(response).not_to have_http_status(:too_many_requests)
    end
  end

  context "when disabled" do
    it "does not block repeated registrations" do
      4.times do
        register!
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end
end
