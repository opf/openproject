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
require_relative "shared_contract_examples"

RSpec.describe Saml::Providers::UpdateContract do
  let(:provider) { build_stubbed(:saml_provider) }

  include_context "as saml provider contract"

  context "when admin" do
    let(:current_user) { build_stubbed(:admin) }

    describe "additional_form_action_urls" do
      let(:provider) { build_stubbed(:saml_provider, additional_form_action_urls: urls) }
      let(:urls) { ["https://idp.example.com/login", "http://broker.example.com:8080"] }

      it_behaves_like "contract is valid"

      context "with an entry that is not an absolute HTTP(S) URL" do
        let(:urls) { ["https://idp.example.com/login", "idp.example.com", "ftp://idp.example.com"] }

        it_behaves_like "contract is invalid", additional_form_action_urls: :url_list_invalid
      end
    end
  end

  describe "allowed_clock_drift persisted out of bounds" do
    let(:current_user) { build_stubbed(:admin) }
    let(:provider) { build_stubbed(:saml_provider, allowed_clock_drift: -0.5) }

    it_behaves_like "contract is valid"
  end
end
