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

RSpec.describe Import::JiraServerVersion do
  describe ".from_server_info" do
    it "reads the version numbers" do
      server_version = described_class.from_server_info("version" => "11.3.3-m0001", "versionNumbers" => [11, 3, 3])

      expect(server_version.to_s).to eq("11.3.3")
    end

    it "falls back to the version string without version numbers" do
      server_version = described_class.from_server_info("version" => "10.3.11")

      expect(server_version.to_s).to eq("10.3.11")
    end

    it "is unknown without any version field" do
      expect(described_class.from_server_info("serverTitle" => "Jira").status).to eq(:unknown)
    end

    it "is unknown for a response that is not a hash" do
      expect(described_class.from_server_info(nil).status).to eq(:unknown)
    end
  end

  describe "#status" do
    {
      "8.13.0" => :unsupported,
      "8.14" => :supported,
      "8.20.30" => :supported,
      "9.12.0" => :supported,
      "10.3.11" => :supported,
      "11.3.3" => :supported,
      "12.0.0" => :unsupported,
      "7.13.18" => :unsupported,
      "1001.0.0-SNAPSHOT" => :unsupported,
      "" => :unknown,
      "unknown" => :unknown
    }.each do |raw_version, status|
      it "is #{status} for #{raw_version.inspect}" do
        expect(described_class.new(raw_version).status).to eq(status)
      end
    end
  end

  describe "#warning" do
    it "is nil for a supported version" do
      expect(described_class.new("11.3.3").warning).to be_nil
    end

    it "names an unsupported version" do
      expect(described_class.new("12.0.0").warning)
        .to eq(I18n.t(:"admin.jira.server_version.unsupported", version: "12.0.0"))
    end

    it "explains an unknown version" do
      expect(described_class.new(nil).warning).to eq(I18n.t(:"admin.jira.server_version.unknown"))
    end
  end

  describe "#supports_auth_method?" do
    {
      ["8.20.30", "bearer"] => false,
      ["8.20.30", "basic"] => true,
      ["9.0.0", "bearer"] => true,
      ["11.3.3", "bearer"] => true,
      ["", "bearer"] => true
    }.each do |(raw_version, auth_method), supported|
      it "is #{supported} for #{auth_method} on #{raw_version.inspect}" do
        expect(described_class.new(raw_version).supports_auth_method?(auth_method)).to be(supported)
      end
    end
  end
end
