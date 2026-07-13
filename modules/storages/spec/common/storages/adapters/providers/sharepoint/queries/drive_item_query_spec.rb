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
        module Queries
          RSpec.describe Internal::DriveItemQuery, :disable_ssrf_filter, :vcr, :webmock do
            let(:storage) { create(:sharepoint_storage, :sandbox) }
            let(:auth_strategy) { Adapters::Registry["sharepoint.authentication.userless"].call }
            let(:drive_id) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Qconfm2i6SKEoCmuGYqQK" }
            let(:item_id) { Peripherals::ParentFolder.new("01ANJ53W6FB7TEDYKAZVCKYK5WKIX66ZTF") }

            subject(:query) { described_class.new(storage) }

            context "with selected fields", vcr: "sharepoint/drive_item_query_select" do
              it "returns the drive item payload" do
                result = Authentication[auth_strategy].call(storage:) do |http|
                  query.call(http:, drive_id:, item_id:, fields: %w[id name])
                end

                expect(result).to be_success
                expect(result.value!).to include(
                  id: "01ANJ53W6FB7TEDYKAZVCKYK5WKIX66ZTF",
                  name: "Berlin's office Christmas"
                )
              end
            end

            context "with expand requested", vcr: "sharepoint/drive_item_query_expand" do
              it "returns the expanded list item payload" do
                result = Authentication[auth_strategy].call(storage:) do |http|
                  query.call(http:, drive_id:, item_id:, fields: %w[id name], expand: %w[listItem])
                end

                expect(result).to be_success
                expect(result.value!).to include(:listItem)
                expect(result.value!.dig(:listItem, :parentReference, :id))
                  .to eq("0c9632a6-7219-4422-b66f-324a6f61eecd")
              end
            end
          end
        end
      end
    end
  end
end
