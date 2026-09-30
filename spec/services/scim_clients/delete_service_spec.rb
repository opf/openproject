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
require "services/base_services/behaves_like_delete_service"

RSpec.describe ScimClients::DeleteService, type: :model do
  subject { instance.call }

  let(:instance) { described_class.new(user:, model: scim_client) }
  let(:user) { build_stubbed(:admin) }
  let!(:scim_client) do
    # loading the freshly created client from the database, so that associations are not preloaded
    # (because this leads to different behaviour after destroy)
    ScimClient.find(create(:scim_client, service_account:).id)
  end
  let(:service_account) { create(:service_account, authentication_provider: create(:oidc_provider)) }

  it_behaves_like "BaseServices delete service" do
    let(:model_instance) { scim_client }
  end

  it "locks the service account" do
    subject
    expect(service_account.reload).to be_locked
  end

  it "deassociates the service account from its authentication provider" do
    expect { subject }.to change(UserAuthProviderLink, :count).from(1).to(0)
  end
end
