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

RSpec.describe API::V3::FileLinks::FileLinkRepresenter, "parsing" do
  include API::V3::Utilities::PathHelper

  let(:file_link) { build_stubbed(:file_link) }
  let(:storage) { build_stubbed(:nextcloud_storage) }

  let(:current_user) { build_stubbed(:user) }

  before do
    allow(Storages::Storage).to receive(:find_by) do |args|
      args[:host] == storage.host ? storage : nil
    end
  end

  describe "parsing" do
    subject(:parsed) { representer.from_hash parsed_hash }

    let(:representer) do
      described_class.create(file_link, current_user:)
    end

    let(:parsed_hash) do
      {
        "_links" => {
          "storageUrl" => {
            "href" => storage.host
          }
        },
        "originData" => {
          "id" => 5503,
          "name" => "logo.png",
          "mimeType" => "image/png",
          "createdAt" => "2021-12-19T09:42:10.170Z",
          "lastModifiedAt" => "2021-12-20T14:00:13.987Z",
          "createdByName" => "Luke Skywalker",
          "lastModifiedByName" => "Anakin Skywalker"
        }
      }
    end

    describe "storage" do
      context "if storage url is given with trailing slashes" do
        let(:parsed_hash) do
          {
            "_links" => {
              "storageUrl" => {
                "href" => "#{storage.host}/////"
              }
            }
          }
        end

        it "is parsed correctly" do
          expect(parsed).to have_attributes(storage_id: storage.id)
        end
      end

      context "if storage is configured with legacy url format (without trailing slash)" do
        let(:storage) { build_stubbed(:nextcloud_storage, host: "https://host.without-trailing.slash") }

        it "is parsed correctly" do
          expect(parsed).to have_attributes(storage_id: storage.id)
        end
      end

      context "if storage is given as resource" do
        let(:parsed_hash) do
          {
            "_links" => {
              "storage" => {
                "href" => api_v3_paths.storage(storage.id)
              }
            }
          }
        end

        it "is parsed correctly" do
          expect(parsed).to have_attributes(storage_id: storage.id)
        end
      end
    end

    describe "originData" do
      it "is parsed correctly" do
        expect(parsed).to have_attributes(storage_id: storage.id,
                                          origin_id: "5503",
                                          origin_name: "logo.png",
                                          origin_mime_type: "image/png",
                                          origin_created_by_name: "Luke Skywalker",
                                          origin_last_modified_by_name: "Anakin Skywalker",
                                          origin_created_at: DateTime.new(2021, 12, 19, 9, 42, 10.17, "+00:00").in_time_zone,
                                          origin_updated_at: DateTime.new(2021, 12, 20, 14, 0, 13.987, "+00:00").in_time_zone)
      end
    end
  end
end
