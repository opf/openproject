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

module Storages
  module Adapters
    module Providers
      module Sharepoint
        module Commands
          RSpec.describe CreateListCommand, :disable_ssrf_filter, :webmock do
            let(:storage) { create(:sharepoint_storage, :sandbox) }

            let(:site_url) { URI.parse(storage.host).host }
            let(:input_data) do
              ProviderInput::CreateList.build(
                name: "OpenProject Test",
                description: "A document library used in testing the Create List Command"
              ).value!
            end

            let(:auth_strategy) { Registry["sharepoint.authentication.userless"].call }

            it "creates a list", vcr: "sharepoint/create_list_success" do
              result = described_class.call(storage:, auth_strategy:, input_data:)

              expect(result).to be_success
              drive = result.value!

              expect(drive.name).to eq(input_data.name)
              expect(drive.location).to eq(UrlBuilder.path("/", input_data.name))
              expect(drive.permissions).to eq([:readable])

              permissions = check_permissions(drive.id)
              expect(permissions.size).to eq(1)
              expect(permissions.dig(0, :roles)).to contain_exactly("owner")
            ensure
              delete_created_list(input_data.name)
            end

            it "returns a Results::StorageFile for the list drive", vcr: "sharepoint/create_list_success" do
              result = described_class.call(storage:, auth_strategy:, input_data:)
              drive = result.value!

              expect(drive).to be_a(Results::StorageFile)
              expect(drive.name).to eq(input_data.name)
              expect(drive.location).to eq(UrlBuilder.path("/", input_data.name))
              expect(drive.permissions).to eq([:readable])
            ensure
              delete_created_list(input_data.name)
            end

            describe "error handling" do
              it "returns a conflict error if a list with the same name already exists", vcr: "sharepoint/create_list_conflict" do
                described_class.call(storage:, auth_strategy:, input_data:)
                result = described_class.call(storage:, auth_strategy:, input_data:)

                expect(result).to be_failure
                error = result.failure

                expect(error.code).to eq(:conflict)
              ensure
                delete_created_list(input_data.name)
              end
            end

            private

            def delete_created_list(name)
              Authentication[auth_strategy].call(storage:) do |http|
                http.delete(list_uri(name)).raise_for_status
              end
            end

            def check_permissions(drive_id)
              Authentication[auth_strategy].call(storage:) do |http|
                response = http.get("https://graph.microsoft.com/v1.0/drives/#{drive_id}/root/permissions").raise_for_status
                response.json(symbolize_keys: true)[:value]
              end
            end

            def list_uri(name)
              "https://graph.microsoft.com/v1.0/sites/#{site_url}:/sites/OPTest:/lists/#{CGI.escape_uri_component(name)}"
            end
          end
        end
      end
    end
  end
end
