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

RSpec.describe API::V3::OAuth::OAuthApplicationsRepresenter, "rendering" do
  let(:user) { build_stubbed(:user) }
  let(:oauth_application) { build_stubbed(:oauth_application) }
  let(:representer) { described_class.new(oauth_application, current_user: user, embed_links: true) }

  subject(:generated) { representer.to_json }

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { "OAuthApplication" }
    end

    it_behaves_like "property", :id do
      let(:value) { oauth_application.id }
    end

    it_behaves_like "property", :name do
      let(:value) { oauth_application.name }
    end

    it_behaves_like "property", :clientId do
      let(:value) { oauth_application.uid }
    end

    it_behaves_like "datetime property", :createdAt do
      let(:value) { oauth_application.created_at }
    end

    it_behaves_like "datetime property", :updatedAt do
      let(:value) { oauth_application.updated_at }
    end

    it_behaves_like "property", :scopes do
      let(:value) { ["api_v3"] }
    end

    describe "confidential" do
      context "if the oauth application is confidential" do
        it_behaves_like "property", :confidential do
          let(:value) { true }
        end
      end

      context "if the oauth application is not confidential" do
        let(:oauth_application) { build_stubbed(:oauth_application, confidential: false) }

        it_behaves_like "property", :confidential do
          let(:value) { false }
        end
      end
    end

    describe "clientSecret" do
      context "if the oauth application is not confidential" do
        let(:oauth_application) { build_stubbed(:oauth_application, confidential: false) }

        it_behaves_like "no property", :clientSecret
      end

      context "if the oauth application is confidential, but not just created" do
        it_behaves_like "no property", :clientSecret
      end

      context "if the oauth application is confidential and just created" do
        before do
          allow(oauth_application).to receive_messages(plaintext_secret: "my-secret")
        end

        it_behaves_like "property", :clientSecret do
          let(:value) { "my-secret" }
        end
      end
    end
  end

  describe "_links" do
    describe "self" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { "/api/v3/oauth_applications/#{oauth_application.id}" }
        let(:title) { oauth_application.name }
      end
    end

    describe "redirectUri" do
      it_behaves_like "has a link collection" do
        let(:link) { "redirectUri" }
        let(:hrefs) { [{ href: oauth_application.redirect_uri }] }
      end

      context "if multiple redirect uris are defined" do
        let(:oauth_application) do
          build_stubbed(:oauth_application, redirect_uri: "https://my.deathstar.com\nhttps://starkiller.base.fo")
        end

        it_behaves_like "has a link collection" do
          let(:link) { "redirectUri" }
          let(:hrefs) { [{ href: "https://my.deathstar.com" }, { href: "https://starkiller.base.fo" }] }
        end
      end
    end
  end
end
