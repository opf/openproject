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

require_relative "../shared_examples"

RSpec.describe Bim::Bcf::API::V2_1::Auth::SingleRepresenter, "rendering" do
  let(:instance) { described_class.new(nil) }

  include OpenProject::StaticRouting::UrlHelpers

  subject { instance.to_json }

  describe "attributes" do
    before do
      allow(OpenProject::Configuration)
        .to receive(:rails_relative_url_root)
        .and_return("/blubs")
    end

    context "oauth2_auth_url" do
      it_behaves_like "attribute" do
        let(:value) { "http://localhost:3000/blubs/oauth/authorize" }
        let(:path) { "oauth2_auth_url" }
      end
    end

    context "oauth2_token_url" do
      it_behaves_like "attribute" do
        let(:value) { "http://localhost:3000/blubs/oauth/token" }
        let(:path) { "oauth2_token_url" }
      end
    end

    context "http_basic_supported" do
      it_behaves_like "attribute" do
        let(:value) { false }
        let(:path) { "http_basic_supported" }
      end
    end

    context "supported_oauth2_flows" do
      it_behaves_like "attribute" do
        let(:value) { %w(authorization_code_grant client_credentials) }
        let(:path) { "supported_oauth2_flows" }
      end
    end
  end
end
