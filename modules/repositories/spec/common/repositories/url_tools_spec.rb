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

RSpec.describe Repositories::UrlTools do
  describe ".same_base_path?" do
    def same_base_path?(url, base: "https://gitlab.example.com:8443/gitlab")
      described_class.same_base_path?(base:, url:)
    end

    it "is true for a URL below the base path" do
      expect(same_base_path?("https://gitlab.example.com:8443/gitlab/group/project")).to be(true)
    end

    it "is true for the base URL itself, with or without a trailing slash" do
      expect(same_base_path?("https://gitlab.example.com:8443/gitlab")).to be(true)
      expect(same_base_path?("https://gitlab.example.com:8443/gitlab/")).to be(true)
    end

    it "accepts any URL on the host when the base has no path" do
      expect(same_base_path?("https://gitlab.example.com/group/project", base: "https://gitlab.example.com"))
        .to be(true)
    end

    it "accepts URI objects" do
      expect(same_base_path?(URI("https://gitlab.example.com:8443/gitlab/group"),
                             base: URI("https://gitlab.example.com:8443/gitlab"))).to be(true)
    end

    it "ignores the case of the host" do
      expect(same_base_path?("https://GitLab.example.com:8443/gitlab/group/project")).to be(true)
    end

    it "is false for a different port" do
      expect(same_base_path?("https://gitlab.example.com/gitlab/group/project")).to be(false)
    end

    it "is false for a path that merely starts with the base path" do
      expect(same_base_path?("https://gitlab.example.com:8443/gitlab-mirror/project")).to be(false)
    end

    it "is false for a different scheme" do
      expect(same_base_path?("http://gitlab.example.com:8443/gitlab/group/project")).to be(false)
    end

    it "is false for a host that merely ends with the base host" do
      expect(same_base_path?("https://evil-gitlab.example.com:8443/gitlab/group/project")).to be(false)
    end

    it "is false for a base without a host" do
      expect(same_base_path?("https://gitlab.example.com/group", base: nil)).to be(false)
      expect(same_base_path?("/group", base: "/")).to be(false)
    end

    it "is false for an invalid URL or base" do
      expect(same_base_path?("https://exa mple.com")).to be(false)
      expect(same_base_path?("https://gitlab.example.com/group", base: "https://exa mple.com")).to be(false)
    end
  end
end
