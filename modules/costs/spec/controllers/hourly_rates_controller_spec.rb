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

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper.rb")

RSpec.describe HourlyRatesController do
  shared_let(:admin) { create(:admin) }

  let(:user) { create(:user) }
  let(:default_rate) { create(:default_hourly_rate, user:) }

  describe "PUT update" do
    describe "WHEN trying to update with an invalid rate value" do
      let(:params) do
        {
          id: user.id,
          user: { "existing_rate_attributes" => { default_rate.id.to_s => { "valid_from" => default_rate.valid_from.to_s,
                                                                            "rate" => "2d5" } } }
        }
      end

      before do
        as_logged_in_user admin do
          post :update, params:
        end
      end

      it "renders the edit template" do
        expect(response).to render_template("edit")
      end

      it "displays an error message" do
        actual_message = assigns(:user).default_rates.first.errors.messages[:rate].first
        expect(actual_message).to eq(I18n.t("activerecord.errors.messages.not_a_number"))
      end
    end
  end
end
