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

RSpec.describe OpenIDConnect::Provider do
  let(:params) do
    {}
  end
  let(:provider) do
    described_class.initialize_with({ name: "azure", identifier: "id", secret: "secret" }.merge(params))
  end

  def auth_plugin
    OpenProject::Plugins::AuthPlugin
  end

  describe "limit_self_registration" do
    before do
      # required so that the auth plugin sees any providers (ee feature)
      allow(EnterpriseToken).to receive(:show_banners?).and_return false
    end

    context "with no limited providers" do
      it "shows the provider as limited" do
        provider.save
        expect(auth_plugin).to be_limit_self_registration provider: provider.name
      end

      context "when set to true" do
        let(:params) do
          { limit_self_registration: true }
        end

        it "saving the provider makes it limited" do
          provider.save

          expect(auth_plugin).to be_limit_self_registration provider: provider.name
        end
      end

      context "when set to false" do
        let(:params) do
          { limit_self_registration: false }
        end

        it "saving the provider does nothing" do
          provider.save

          expect(auth_plugin).not_to be_limit_self_registration provider: provider.name
        end
      end
    end

    context(
      "with a limited provider",
      with_settings: {
        plugin_openproject_openid_connect: {
          "providers" => {
            "azure" => {
              "name" => "azure",
              "identifier" => "id",
              "secret" => "secret",
              "limit_self_registration" => true
            }
          }
        }
      }
    ) do
      it "shows the provider as limited" do
        expect(auth_plugin).to be_limit_self_registration provider: provider.name
      end
    end
  end
end
