#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.

require 'spec_helper'

describe "user limits in users API", type: :request do
  include API::V3::Utilities::PathHelper

  let(:path) { api_v3_paths.users }
  let(:admin) { FactoryBot.build(:admin) }

  let(:parameters) do
    {
      login: "p.putzig",
      firstName: "Peter",
      lastName: "Putzig",
      email: "p.putzig@openproject.com",
      password: "hallohallo"
    }
  end

  let(:user) { User.find_by(login: parameters[:login]) }

  before do
    login_as admin
  end

  def send_request
    header "Content-Type", "application/json"

    post path, parameters.to_json
  end

  shared_examples "creating the user" do
    let(:response_status) { 201 }
    let(:status) { :active }

    def status_name(status)
      User::STATUSES.find { |k, v| v == status }.first
    end

    before do
      send_request

      expect(last_response.status).to eq response_status
    end

    it "creates the new user" do
      expect(user).to be_present
    end

    it "sets the right user status" do
      expect(status_name(user.status)).to eq status
    end
  end

  context "with user limit reached" do
    before do
      allow(OpenProject::Enterprise).to receive(:user_limit_reached?).and_return(true)
    end

    context "with fail fast (hard limit)" do
      before do
        allow(OpenProject::Enterprise).to receive(:fail_fast?).and_return(true)
      end

      it "does not create the user" do
        send_request

        expect(user).not_to be_present

        expect(last_response.status).to eq 422
        expect(JSON.parse(last_response.body)["message"]).to eq "User limit reached."
      end
    end

    context "without fail fast (soft limit)" do
      before do
        allow(OpenProject::Enterprise).to receive(:fail_fast?).and_return(false)
      end

      it_behaves_like "creating the user" do
        let(:status) { :registered }
      end
    end
  end

  context "with user limit not reached" do
    it_behaves_like "creating the user"
  end
end
