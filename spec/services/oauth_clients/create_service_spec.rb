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
require "services/base_services/behaves_like_create_service"

RSpec.describe OAuthClients::CreateService, type: :model do
  it_behaves_like "BaseServices create service" do
    let(:factory) { :oauth_client }

    context "if another oauth client for the given integration exists" do
      let(:storage) { create(:nextcloud_storage) }
      let!(:existing_client) { create(:oauth_client, integration: storage) }
      let!(:model_instance) { build_stubbed(:oauth_client, integration: storage) }
      let(:call_attributes) { { name: "Death Star", integration: storage } }

      it "overwrites the existing oauth client" do
        # Test setup still returns success, but `subject` must be initialized
        expect(subject).to be_success
        expect(OAuthClient.where(id: existing_client.id)).not_to exist
      end
    end
  end
end
