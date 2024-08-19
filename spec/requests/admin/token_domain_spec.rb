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

RSpec.describe "Enterprise Edition token domain",
               :skip_csrf, type: :rails_request do
  let(:current_user) { create(:admin) }
  let(:valid_token) { Rails.root.join("spec/fixtures/ee_tokens/v2_1_user_test_host.token").read }
  let(:invalid_token) { Rails.root.join("spec/fixtures/ee_tokens/v2_1_user_localhost_3001.token").read }
  let(:ee_token) { valid_token }

  before do
    login_as(current_user)
  end

  shared_context "when uploading a token" do
    before do
      post "/admin/enterprise",
           params: {
             "enterprise_token[encoded_token]": ee_token
           }
    end
  end

  describe "initial upload" do
    context "with correct domain" do
      it_behaves_like "when uploading a token" do
        it "saves the token" do
          expect(response).to be_redirect
          expect(EnterpriseToken.current).to be_present
        end
      end
    end

    context "with incorrect domain" do
      let(:ee_token) { invalid_token }

      it_behaves_like "when uploading a token" do
        it "shows an invalid domain error" do
          expect(body).to have_text "Domain is invalid."
        end
      end
    end
  end

  context "with an active token" do
    let!(:token) do
      obj = EnterpriseToken.new(encoded_token: invalid_token, created_at: 5.days.ago, updated_at: 5.days.ago)
      obj.save!(validate: false)
      obj
    end

    describe "replacing the token" do
      context "with correct domain" do
        it_behaves_like "when uploading a token" do
          it "updates the token" do
            expect(response).to be_redirect
            expect(EnterpriseToken.current.updated_at.to_date).to eq(Time.zone.today)
          end
        end
      end

      context "with incorrect domain" do
        it_behaves_like "when uploading a token" do
          let(:ee_token) { invalid_token }

          it "shows an invalid domain error", :aggregate_failures do
            expect(page).to have_text "Domain is invalid."
          end
        end
      end
    end
  end
end
