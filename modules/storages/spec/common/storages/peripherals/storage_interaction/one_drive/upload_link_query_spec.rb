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
require_module_spec_helper

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::UploadLinkQuery, :webmock do
  let(:storage) { create(:sharepoint_dev_drive_storage) }
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials.strategy
  end

  it_behaves_like "upload_link_query: basic query setup"

  it_behaves_like "upload_link_query: validating input data"

  context "when requesting an upload link for an existing file", vcr: "one_drive/upload_link_success" do
    let(:upload_data) do
      Storages::UploadData.new(folder_id: "01AZJL5PN6Y2GOVW7725BZO354PWSELRRZ", file_name: "DeathStart_blueprints.tiff")
    end
    let(:token) do
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBfZGlzcGxheW5hbWUiOiJPcGVuUHJvamVjdCBEZXYgQXBwIiwiYXVkIjoiMDAwMDA" \
        "wMDMtMDAwMC0wZmYxLWNlMDAtMDAwMDAwMDAwMDAwL2Zpbm4uc2hhcmVwb2ludC5jb21ANGQ0NGJmMzYtOWI1Ni00NWMwLTg4MDctYmJmMzg" \
        "2ZGQwNDdmIiwiY2lkIjoiR3k0SDY0aTF2MEN6NXVxU0tDTkNodz09IiwiZW5kcG9pbnR1cmwiOiJ6cFdrZGttVmxSUEZYRG55eWVmb0thaUg" \
        "ycFhmV0RUdmkvNTVReHVYSlAwPSIsImVuZHBvaW50dXJsTGVuZ3RoIjoiMjc3IiwiZXhwIjoiMTcxNTA5MjYxOCIsImlwYWRkciI6IjIwLjE" \
        "5MC4xOTAuMTAwIiwiaXNsb29wYmFjayI6IlRydWUiLCJpc3MiOiIwMDAwMDAwMy0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDAiLCJuYW1" \
        "laWQiOiI0MjYyZGYyYi03N2JiLTQ5YzItYTVkZi0yODM1NWRhNjc2ZDJANGQ0NGJmMzYtOWI1Ni00NWMwLTg4MDctYmJmMzg2ZGQwNDdmIiw" \
        "ibmJmIjoiMTcxNTAwNjIxOCIsInJvbGVzIjoiYWxsc2l0ZXMucmVhZCBhbGxzaXRlcy53cml0ZSBhbGxmaWxlcy53cml0ZSIsInNpdGVpZCI" \
        "6Ik1XSTBZalkxTnpZdE9UQTJaQzAwWkRrMExUaG1ORGt0Tm1Rd01HRTVOVEEzWWpVdyIsInR0IjoiMSIsInZlciI6Imhhc2hlZHByb29mdG9" \
        "rZW4ifQ.UMqPAjuiXSt1rQgFiE0h-k3wkBZ3DmF3I3Nj_zYuYuI"
    end
    let(:upload_url) do
      "https://finn.sharepoint.com/sites/openprojectfilestoragetests/_api/v2.0/drives/" \
        "b!dmVLG22QlE2PSW0AqVB7UOhZ8n7tjkVGkgqLNnuw2OBb-brzKzZAR4DYT1k9KPXs/items/01AZJL5PKRK4XUJQQH3JHIUGK2ALGEJEK4/" \
        "uploadSession?guid=%2789f10eb4-b8d9-4ba9-ab64-eb1e6d39b2ee%27&overwrite=False&rename=True&dc=0" \
        "&tempauth=#{token}"
    end
    let(:upload_method) { :put }

    it_behaves_like "upload_link_query: successful upload link response"
  end

  context "when requesting an upload link for a not existing file", vcr: "one_drive/upload_link_not_found" do
    let(:upload_data) do
      Storages::UploadData.new(folder_id: "04AZJL5PN6Y2GOVW7725BZO354PWSELRRZ", file_name: "DeathStart_blueprints.tiff")
    end
    let(:error_source) { described_class }

    it_behaves_like "upload_link_query: not found"
  end
end
