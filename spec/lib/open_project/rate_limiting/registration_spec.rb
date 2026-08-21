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

RSpec.describe OpenProject::RateLimiting::Registration do
  describe ".enabled?" do
    it "is disabled when the limit is 0" do
      expect(described_class).not_to be_enabled
    end

    context "with a positive limit", with_settings: { registration_rate_limit: 10 } do
      it { expect(described_class).to be_enabled }
    end
  end

  describe "#default_limit" do
    context "with a positive limit", with_settings: { registration_rate_limit: 7 } do
      it "uses the configured value" do
        expect(described_class.new.default_limit).to eq 7
      end
    end
  end

  describe "#per_ip?" do
    it "defaults to counting per client IP" do
      expect(described_class.new).to be_per_ip
    end

    context "when disabled", with_settings: { registration_rate_limit_per_ip: false } do
      it { expect(described_class.new).not_to be_per_ip }
    end
  end

  describe "#discriminator" do
    subject(:rule) { described_class.new }

    def request_for(path, method: "POST", ip_address: "192.0.2.1")
      env = Rack::MockRequest.env_for(path, method:, "REMOTE_ADDR" => ip_address)
      Rack::Attack::Request.new(env)
    end

    it "matches the register path" do
      expect(rule.send(:discriminator, request_for("/account/register"))).to eq "192.0.2.1"
    end

    it "matches an optional format suffix that still routes to register" do
      expect(rule.send(:discriminator, request_for("/account/register.json"))).to eq "192.0.2.1"
    end

    context "with a relative URL root", with_config: { rails_relative_url_root: "/openproject" } do
      it "matches the register path under that prefix" do
        expect(rule.send(:discriminator, request_for("/openproject/account/register"))).to eq "192.0.2.1"
      end
    end

    it "does not match other paths" do
      expect(rule.send(:discriminator, request_for("/account/lost_password"))).to be_nil
    end

    it "does not match a path that merely ends with /account/register" do
      expect(rule.send(:discriminator, request_for("/evil/account/register"))).to be_nil
    end

    it "does not match GET" do
      expect(rule.send(:discriminator, request_for("/account/register", method: "GET"))).to be_nil
    end
  end
end
