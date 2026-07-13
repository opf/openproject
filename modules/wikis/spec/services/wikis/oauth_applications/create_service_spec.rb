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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Wikis::OAuthApplications::CreateService, type: :model do
  let(:user) { create(:admin) }
  let(:wiki_provider) { create(:xwiki_provider, name: "My XWiki", url: "https://xwiki.example.com/") }
  let(:instance) { described_class.new(user:, wiki_provider:) }

  describe "#call" do
    subject { instance.call }

    it "returns a successful ServiceResult with a Doorkeeper::Application" do
      expect(subject).to be_a(ServiceResult)
      expect(subject).to be_success
      expect(subject.result).to be_a(Doorkeeper::Application)
    end

    it "sets the correct application attributes" do
      result = subject.result
      expect(result.name).to eq(wiki_provider.name)
      expect(result.scopes.to_s).to eq("api_v3")
      expect(result.confidential).to be_truthy
      expect(result.owner).to eq(user)
      expect(result.integration).to eq(wiki_provider)
    end

    it "sets the redirect_uri to the XWiki OIDC callback path without double slashes" do
      expect(subject.result.redirect_uri).to eq("https://xwiki.example.com/oidc/authenticator/callback")
    end
  end
end
