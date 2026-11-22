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
require_module_spec_helper

RSpec.describe Wikis::OAuthApplications::UpdateService, type: :model do
  let(:user) { create(:admin) }
  let(:wiki_provider) { create(:xwiki_provider, name: "My XWiki", url: "https://xwiki.example.com/") }
  let!(:oauth_application) { create(:oauth_application, integration: wiki_provider, uid: "old-client-id") }
  let(:instance) { described_class.new(user:, wiki_provider:) }

  describe "#call" do
    subject { instance.call(client_id: "my-client-id", client_secret: "my-client-secret") }

    it "returns a successful ServiceResult updating the existing application" do
      expect(subject).to be_success
      expect(subject.result).to eq(oauth_application)
    end

    it "updates name, redirect_uri and client id" do
      application = subject.result.reload

      expect(application.name).to eq("My XWiki")
      expect(application.redirect_uri).to eq("https://xwiki.example.com/oidc/authenticator/callback")
      expect(application.uid).to eq("my-client-id")
    end

    it "stores the given client secret hashed" do
      application = subject.result.reload

      expect(application.secret).not_to eq("my-client-secret")
      expect(application.secret_matches?("my-client-secret")).to be(true)
    end

    it "allows looking up the application by its credentials" do
      subject

      expect(Doorkeeper::Application.by_uid_and_secret("my-client-id", "my-client-secret")).to eq(oauth_application)
    end

    context "when the given secret matches the stored one" do
      before do
        oauth_application.update!(secret: Doorkeeper::Application.secret_strategy.transform_secret("my-client-secret"))
      end

      it "keeps the stored secret hash" do
        expect { subject }.not_to change { oauth_application.reload.secret }
      end
    end

    context "without client credentials given" do
      subject { instance.call }

      it "keeps client id and secret" do
        expect { subject }.not_to change { oauth_application.reload.attributes.slice("uid", "secret") }
      end
    end
  end
end
