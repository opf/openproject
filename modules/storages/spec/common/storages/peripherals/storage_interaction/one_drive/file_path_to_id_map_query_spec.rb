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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::FilePathToIdMapQuery, :webmock do
  let(:storage) { create(:sharepoint_dev_drive_storage) }
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials.strategy
  end

  it_behaves_like "file_path_to_id_map_query: basic query setup"

  context "with parent folder being root", vcr: "one_drive/file_path_to_id_map_query_root" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/") }
    let(:expected_ids) do
      {
        "/" => "01AZJL5PN6Y2GOVW7725BZO354PWSELRRZ",
        "/Folder with spaces" => "01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU",
        "/Folder with spaces/very empty folder" => "01AZJL5PMGEIRPHZPHRRH2NM3D734VIR7H",
        "/Folder with spaces/wordle1.png" => "01AZJL5PPMSBBO3R2BIZHJFCELSW3RP7GN",
        "/Folder with spaces/wordle2.png" => "01AZJL5PIIFUD6A765KBAIAEMYACAFB2WP",
        "/Folder with spaces/wordle3.png" => "01AZJL5PL4AUJEU43CQZFJKN7BQPRP3BLF",
        "/Folder" => "01AZJL5PMAXGDWAAKMEBALX4Q6GSN5BSBR",
        "/Folder/Images" => "01AZJL5PMIF7ND3KH6FVDLZYP3E36ERFGI",
        "/Folder/Subfolder" => "01AZJL5PPWP5UOATNRJJBYJG5TACDHEUAG",
        "/Folder/Ümlæûts" => "01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB",
        "/Folder/Document.docx" => "01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU",
        "/Folder/Sheet.xlsx" => "01AZJL5PLB7SH7633RMBHIH6KVMQRU4RJS",
        "/Folder/Images/der_laufende.jpeg" => "01AZJL5PLZFCARRQIDFJF36UL2WTLXTNSY",
        "/Folder/Images/written_in_stone.webp" => "01AZJL5PLNCKWYI752YBHYYJ6RBFZWOZ46",
        "/Folder/Subfolder/NextcloudHub.md" => "01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA",
        "/Folder/Subfolder/test.txt" => "01AZJL5PLOL2KZTJNVFBCJWFXYGYVBQVMZ",
        "/Folder/Ümlæûts/Anrüchiges deutsches Dokument.docx" => "01AZJL5PNDURPQGKUSGFCJQJMNNWXKTHSE",
        "/Permissions Folder" => "01AZJL5PN3LVLHH2RSZZDJ6ZFAD3OWSGYB"
      }
    end

    it_behaves_like "file_path_to_id_map_query: successful query"
  end

  context "with a given parent folder", vcr: "one_drive/file_path_to_id_map_query_parent_folder" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("01AZJL5PMAXGDWAAKMEBALX4Q6GSN5BSBR") }
    let(:expected_ids) do
      {
        "/Folder" => "01AZJL5PMAXGDWAAKMEBALX4Q6GSN5BSBR",
        "/Folder/Images" => "01AZJL5PMIF7ND3KH6FVDLZYP3E36ERFGI",
        "/Folder/Subfolder" => "01AZJL5PPWP5UOATNRJJBYJG5TACDHEUAG",
        "/Folder/Ümlæûts" => "01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB",
        "/Folder/Document.docx" => "01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU",
        "/Folder/Sheet.xlsx" => "01AZJL5PLB7SH7633RMBHIH6KVMQRU4RJS",
        "/Folder/Images/der_laufende.jpeg" => "01AZJL5PLZFCARRQIDFJF36UL2WTLXTNSY",
        "/Folder/Images/written_in_stone.webp" => "01AZJL5PLNCKWYI752YBHYYJ6RBFZWOZ46",
        "/Folder/Subfolder/NextcloudHub.md" => "01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA",
        "/Folder/Subfolder/test.txt" => "01AZJL5PLOL2KZTJNVFBCJWFXYGYVBQVMZ",
        "/Folder/Ümlæûts/Anrüchiges deutsches Dokument.docx" => "01AZJL5PNDURPQGKUSGFCJQJMNNWXKTHSE"
      }
    end

    it_behaves_like "file_path_to_id_map_query: successful query"
  end

  context "with not existent parent folder", vcr: "one_drive/file_path_to_id_map_query_invalid_parent" do
    let(:folder) { Storages::Peripherals::ParentFolder.new("/I/just/made/that/up") }
    let(:error_source) { Storages::Peripherals::StorageInteraction::OneDrive::Internal::DriveItemQuery }

    it_behaves_like "file_path_to_id_map_query: not found"
  end
end
