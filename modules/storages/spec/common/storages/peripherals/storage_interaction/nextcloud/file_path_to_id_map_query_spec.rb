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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::FilePathToIdMapQuery, :webmock do
  let(:user) { create(:user) }
  let(:storage) do
    create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
  end
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  it_behaves_like "file_path_to_id_map_query: basic query setup"

  context "with parent folder being root" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/") }

    context "with unset depth (defaults to INFINITY)", vcr: "nextcloud/file_path_to_id_map_query_root_depth_infinite" do
      let(:expected_ids) do
        {
          "/" => "2",
          "/Folder with spaces" => "165",
          "/Folder with spaces/New Requests" => "166",
          "/Folder with spaces/New Requests/I❤️you death star.md" => "167",
          "/Folder with spaces/New Requests/request_002.md" => "168",
          "/Folder with spaces/Ümläuts & spe¢iæl characters" => "360",
          "/Folder with spaces/Ümläuts & spe¢iæl characters/what_have_you_done.md" => "361",
          "/My files" => "169",
          "/My files/android-studio-linux.tar.gz" => "267",
          "/My files/empty" => "172",
          "/My files/Ümlæûts" => "350",
          "/My files/Ümlæûts/Anrüchiges deutsches Dokument.docx" => "351",
          "/Practical_guide_to_BAGGM_Digital.pdf" => "295",
          "/Readme.md" => "268",
          "/VCR" => "773",
          "/VCR/placeholder" => "790"
        }
      end

      it_behaves_like "file_path_to_id_map_query: successful query"
    end

    context "with depth 0", vcr: "nextcloud/file_path_to_id_map_query_root_depth_0" do
      let(:depth) { 0 }
      let(:expected_ids) { { "/" => "2" } }

      it_behaves_like "file_path_to_id_map_query: successful query"
    end

    context "with depth 1", vcr: "nextcloud/file_path_to_id_map_query_root_depth_1" do
      let(:depth) { 1 }
      let(:expected_ids) do
        {
          "/" => "2",
          "/Folder with spaces" => "165",
          "/My files" => "169",
          "/Practical_guide_to_BAGGM_Digital.pdf" => "295",
          "/Readme.md" => "268",
          "/VCR" => "773"
        }
      end

      it_behaves_like "file_path_to_id_map_query: successful query"
    end
  end

  context "with a given parent folder", vcr: "nextcloud/file_path_to_id_map_query_parent_folder" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/Folder") }
    let(:expected_ids) do
      {
        "/Folder" => "169",
        "/Folder/android-studio-2021.3.1.17-linux.tar.gz" => "267",
        "/Folder/empty" => "172",
        "/Folder/Ümlæûts" => "350",
        "/Folder/Ümlæûts/Anrüchiges deutsches Dokument.docx" => "351"
      }
    end

    it_behaves_like "file_path_to_id_map_query: successful query"
  end

  context "with not existent parent folder", vcr: "nextcloud/file_path_to_id_map_query_invalid_parent" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/I/just/made/that/up") }
    let(:error_source) { Storages::Peripherals::StorageInteraction::Nextcloud::Internal::PropfindQuery }

    it_behaves_like "file_path_to_id_map_query: not found"
  end
end
