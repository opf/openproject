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

RSpec.describe Import::Jiras::Validators::ConfigurationValidator do
  subject(:results) { described_class.call(jira).results.map { [it.key, it.state, it.code].compact } }

  let(:url) { "https://jira.example.com" }
  let(:jira) { build(:jira, url:) }

  context "with a URL and a personal access token" do
    it "passes every check" do
      expect(results).to eq([%i[url_valid success], %i[credentials_present success]])
    end
  end

  context "with a URL and basic auth credentials" do
    let(:jira) { build(:jira, :with_basic_auth, url:) }

    it "passes every check" do
      expect(results).to eq([%i[url_valid success], %i[credentials_present success]])
    end
  end

  context "with an invalid URL" do
    let(:url) { "ftp://jira.example.com" }

    it "fails the URL check and skips the credentials" do
      expect(results).to eq([%i[url_valid failure invalid_url], %i[credentials_present skipped]])
    end
  end

  context "without a personal access token" do
    let(:jira) { build(:jira, url:, personal_access_token: nil) }

    it "fails the credentials check" do
      expect(results).to eq([%i[url_valid success], %i[credentials_present failure personal_access_token_missing]])
    end
  end

  context "with basic auth without a username" do
    let(:jira) { build(:jira, :with_basic_auth, url:, basic_auth_username: "") }

    it "fails the credentials check" do
      expect(results).to eq([%i[url_valid success], %i[credentials_present failure basic_auth_username_missing]])
    end
  end

  context "with basic auth without a password" do
    let(:jira) { build(:jira, :with_basic_auth, url:, basic_auth_password: nil) }

    it "fails the credentials check" do
      expect(results).to eq([%i[url_valid success], %i[credentials_present failure basic_auth_password_missing]])
    end
  end
end
