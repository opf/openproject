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

RSpec.describe "Rate limiting lost_password",
               :with_rack_attack,
               type: :rails_request do
  before do
    allow_any_instance_of(ActionController::Base) # rubocop:disable RSpec/AnyInstance
      .to(receive(:protect_against_forgery?))
      .and_return(false)
  end

  it "blocks the request on the fourth try to the same address" do
    3.times do
      post account_lost_password_path,
           params: { mail: "foo@example.com" },
           headers: { "Content-Type": "multipart/form-data" }
      expect(response).to be_successful
    end

    post account_lost_password_path,
         params: { mail: "foo@example.com" },
         headers: { "Content-Type": "multipart/form-data" }
    expect(response).to have_http_status :too_many_requests
    expect(response.body).to include "Your request has been throttled"

    post account_lost_password_path,
         params: { mail: "corrected@example.com" },
         headers: { "Content-Type": "multipart/form-data" }
    expect(response).to be_successful
  end

  context "when disabled", with_config: { rate_limiting: { lost_password: false } } do
    it "does not block post request to any form" do
      # Need to reload rules again after config change
      OpenProject::RateLimiting.set_defaults!

      4.times do
        post account_lost_password_path,
             params: { mail: "foo@example.com" },
             headers: { "Content-Type": "multipart/form-data" }
        expect(response).to be_successful
      end
    end
  end
end
