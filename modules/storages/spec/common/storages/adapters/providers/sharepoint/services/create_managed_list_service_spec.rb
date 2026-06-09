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
        module Services
          RSpec.describe CreateManagedListService, :disable_ssrf_filter, :webmock do
            let(:storage) { create(:sharepoint_storage, :sandbox) }

            subject(:instance) { described_class.new(storage) }

            it "returns a Storage::File for the created drive", vcr: "sharepoint/managed_drive_service_success" do
              service_result = instance.call("OpenProject Test")

              expect(service_result).to be_success
              file = service_result.result

              expect(file).to be_a(Results::StorageFile)
              expect(file.id).to start_with("b!")
              expect(file.name).to eq("OpenProject Test")
            ensure
              delete_created_list("OpenProject Test")
            end

            context "when the drive already exists" do
              it "returns a Storage::File for the created drive", vcr: "sharepoint/managed_drive_service_conflict" do
                service_result = instance.call
                expect(service_result).to be_success

                file = service_result.result
                expect(file).to be_a(Results::StorageFile)
                expect(file.id).to eq("b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Qconfm2i6SKEoCmuGYqQK")
                expect(file.name).to eq("OpenProject")
              end

              it "logs an error message"
            end

            private

            def auth_strategy = Registry["sharepoint.authentication.userless"].call

            def delete_created_list(name)
              Authentication[auth_strategy].call(storage:) do |http|
                http.delete(list_uri(name)).raise_for_status
              end
            end

            def list_uri(name)
              site_url = URI.parse(storage.host).host

              "https://graph.microsoft.com/v1.0/sites/#{site_url}:/sites/OPTest:/lists/#{CGI.escape_uri_component(name)}"
            end
          end
        end
      end
    end
  end
end
