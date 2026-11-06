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

RSpec.describe Repositories::GitlabProvider do
  describe ".for_web_url" do
    let!(:provider) { create(:repository_provider, url: "https://gitlab.example.com") }
    let!(:other_provider) { create(:repository_provider, url: "https://gitlab.example.com:8443/gitlab") }

    it "finds the provider hosting the resource" do
      expect(described_class.for_web_url("https://gitlab.example.com/group/project/-/merge_requests/4"))
        .to eq(provider)
    end

    it "ignores the case of the host" do
      expect(described_class.for_web_url("https://GitLab.example.com/group/project")).to eq(provider)
    end

    it "considers the port and the path of the provider URL" do
      expect(described_class.for_web_url("https://gitlab.example.com:8443/gitlab/group/project"))
        .to eq(other_provider)
    end

    it "does not match a path that merely starts with the provider's path" do
      expect(described_class.for_web_url("https://gitlab.example.com:8443/gitlab-mirror/project")).to be_nil
    end

    it "does not match a different scheme" do
      expect(described_class.for_web_url("http://gitlab.example.com/group/project")).to be_nil
    end

    it "does not match a host that merely ends with the provider's host" do
      expect(described_class.for_web_url("https://evil-gitlab.example.com/group/project")).to be_nil
    end

    it "returns nil for a blank or invalid URL" do
      expect(described_class.for_web_url(nil)).to be_nil
      expect(described_class.for_web_url("https://exa mple.com")).to be_nil
    end
  end
end
