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

RSpec.describe AuthProvider do
  describe "#available=" do
    it "unsets the direct login provider when disabled" do
      provider = create(:oidc_provider)
      Setting.omniauth_direct_login_provider = provider.slug

      provider.update!(available: false)

      expect(Setting.omniauth_direct_login_provider).to be_blank
    end
  end

  describe "#additional_form_action_urls" do
    subject(:provider) { build(:oidc_provider) }

    it "splits text into one URL per line and drops blank lines" do
      provider.additional_form_action_urls = " https://idp.example.com/login \r\n\r\nhttps://broker.example.com\n"

      expect(provider.additional_form_action_urls).to eq %w[https://idp.example.com/login https://broker.example.com]
    end

    it "accepts a list" do
      provider.additional_form_action_urls = ["https://idp.example.com", ""]

      expect(provider.additional_form_action_urls).to eq %w[https://idp.example.com]
    end

    it "defaults to an empty list" do
      expect(provider.additional_form_action_urls).to eq []
    end

    it "is an empty list for providers stored without it" do
      saml_provider = create(:saml_provider)
      saml_provider.update_column(:options, saml_provider.options.except("additional_form_action_urls"))

      expect(described_class.find(saml_provider.id).additional_form_action_urls).to eq []
    end
  end
end
